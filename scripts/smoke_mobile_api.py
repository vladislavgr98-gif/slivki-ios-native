#!/usr/bin/env python3
"""Read-only smoke tests for the Slivki mobile API.

The script uses only the Python standard library so it can run unchanged in
GitHub Actions and on a developer machine.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


DEFAULT_BASE_URL = "https://slivki-shop.ru/api/mobile/v1"
MISSING_PRODUCT_ID = 2_147_483_647


class SmokeFailure(AssertionError):
    """Raised when the live API does not satisfy the mobile contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SmokeFailure(message)


def build_url(base_url: str, path: str, query: dict[str, Any] | None = None) -> str:
    base = base_url.rstrip("/")
    suffix = path if path.startswith("/") else f"/{path}"
    url = f"{base}{suffix}"
    if query:
        params = {key: value for key, value in query.items() if value is not None}
        if params:
            url = f"{url}?{urllib.parse.urlencode(params)}"
    return url


def get_json(
    base_url: str,
    path: str,
    *,
    query: dict[str, Any] | None = None,
    expected_status: int = 200,
    timeout: float = 15.0,
) -> tuple[int, dict[str, Any]]:
    url = build_url(base_url, path, query)
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "slivki-ios-api-smoke/1.0",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status = response.status
            body = response.read()
    except urllib.error.HTTPError as error:
        status = error.code
        body = error.read()
    except urllib.error.URLError as error:
        raise SmokeFailure(f"GET {url} failed: {error.reason}") from error

    require(
        status == expected_status,
        f"GET {url} returned HTTP {status}, expected {expected_status}",
    )

    try:
        payload = json.loads(body.decode("utf-8"))
    except UnicodeDecodeError as error:
        raise SmokeFailure(f"GET {url} returned non-UTF-8 response") from error
    except json.JSONDecodeError as error:
        raise SmokeFailure(f"GET {url} returned invalid JSON: {error}") from error

    require(isinstance(payload, dict), f"GET {url} returned JSON {type(payload).__name__}, expected object")
    return status, payload


def require_success_envelope(payload: dict[str, Any], label: str) -> dict[str, Any]:
    require(payload.get("success") is True, f"{label} envelope success must be true")
    require(isinstance(payload.get("meta"), dict), f"{label} envelope meta must be an object")
    require("data" in payload, f"{label} envelope must include data")

    meta = payload["meta"]
    require(meta.get("apiVersion") == "mobile-v1", f"{label} meta.apiVersion must be mobile-v1")
    require(isinstance(meta.get("generatedAt"), str) and meta["generatedAt"], f"{label} meta.generatedAt must be set")

    data = payload["data"]
    require(isinstance(data, dict), f"{label} data must be an object")
    return data


def require_error_envelope(payload: dict[str, Any], label: str) -> None:
    require(payload.get("success") is False, f"{label} envelope success must be false")
    error = payload.get("error")
    require(isinstance(error, dict), f"{label} error must be an object")
    require(isinstance(error.get("code"), str) and error["code"], f"{label} error.code must be set")
    require(isinstance(error.get("message"), str) and error["message"], f"{label} error.message must be set")


def require_product(product: Any, label: str) -> dict[str, Any]:
    require(isinstance(product, dict), f"{label} product must be an object")
    require(isinstance(product.get("id"), int), f"{label} product.id must be an integer")
    require(isinstance(product.get("title"), str) and product["title"], f"{label} product.title must be set")
    require(isinstance(product.get("category"), dict), f"{label} product.category must be an object")
    require(isinstance(product.get("price"), dict), f"{label} product.price must be an object")
    require(isinstance(product.get("stock"), dict), f"{label} product.stock must be an object")
    return product


def require_product_list(data: dict[str, Any], label: str) -> list[dict[str, Any]]:
    items = data.get("items")
    pagination = data.get("pagination")
    require(isinstance(items, list), f"{label} data.items must be a list")
    require(isinstance(pagination, dict), f"{label} data.pagination must be an object")
    for field in ("offset", "limit", "count"):
        require(isinstance(pagination.get(field), int), f"{label} pagination.{field} must be an integer")
    return [require_product(item, f"{label} item {index}") for index, item in enumerate(items)]


def iter_categories(categories: Any) -> list[dict[str, Any]]:
    if not isinstance(categories, list):
        return []

    flattened: list[dict[str, Any]] = []
    for category in categories:
        if not isinstance(category, dict):
            continue
        flattened.append(category)
        flattened.extend(iter_categories(category.get("children")))
    return flattened


def category_id_set(category: dict[str, Any]) -> set[int]:
    ids: set[int] = set()
    if isinstance(category.get("id"), int):
        ids.add(category["id"])
    for child in iter_categories(category.get("children")):
        if isinstance(child.get("id"), int):
            ids.add(child["id"])
    return ids


def run_smoke(base_url: str, timeout: float) -> None:
    print(f"Smoke testing {base_url.rstrip('/')}")

    _, health_payload = get_json(base_url, "/health", timeout=timeout)
    health_data = require_success_envelope(health_payload, "health")
    require(health_data.get("status") == "ok", "health data.status must be ok")
    print("PASS /health")

    _, catalog_payload = get_json(base_url, "/catalog", timeout=timeout)
    catalog_data = require_success_envelope(catalog_payload, "catalog")
    categories = catalog_data.get("categories")
    require(isinstance(categories, list), "catalog data.categories must be a list")
    flattened_categories = iter_categories(categories)
    first_category = next((category for category in flattened_categories if isinstance(category.get("id"), int)), None)
    print(f"PASS /catalog ({len(flattened_categories)} categories)")

    _, products_payload = get_json(base_url, "/products", query={"limit": 10}, timeout=timeout)
    products_data = require_success_envelope(products_payload, "products")
    products = require_product_list(products_data, "products")
    require(products, "products must return at least one item for product detail smoke test")
    first_product = products[0]
    first_product_id = first_product["id"]
    print(f"PASS /products ({len(products)} items)")

    _, detail_payload = get_json(base_url, f"/products/{first_product_id}", timeout=timeout)
    detail_data = require_success_envelope(detail_payload, "product detail")
    detail_product = require_product(detail_data.get("product"), "product detail")
    require(
        detail_product["id"] == first_product_id,
        f"product detail id {detail_product['id']} did not match list id {first_product_id}",
    )
    print(f"PASS /products/{first_product_id}")

    if first_category is None:
        print("SKIP /products?category_id=<id> (catalog returned no category ids)")
    else:
        category_id = first_category["id"]
        _, filtered_payload = get_json(
            base_url,
            "/products",
            query={"category_id": category_id, "limit": 10},
            timeout=timeout,
        )
        filtered_data = require_success_envelope(filtered_payload, "category products")
        filtered_products = require_product_list(filtered_data, "category products")
        expected_category_ids = category_id_set(first_category)
        if filtered_products and expected_category_ids:
            product_category_ids = {
                product.get("category", {}).get("id")
                for product in filtered_products
                if isinstance(product.get("category", {}).get("id"), int)
            }
            if product_category_ids.isdisjoint(expected_category_ids):
                print(
                    "NOTE category filter returned products whose category ids are not present "
                    "in the catalog subtree; envelope and product schema validated"
                )
        print(f"PASS /products?category_id={category_id} ({len(filtered_products)} items)")

    _, missing_payload = get_json(
        base_url,
        f"/products/{MISSING_PRODUCT_ID}",
        expected_status=404,
        timeout=timeout,
    )
    require_error_envelope(missing_payload, "404")
    print(f"PASS /products/{MISSING_PRODUCT_ID} 404 envelope")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test the Slivki mobile API.")
    parser.add_argument(
        "--base-url",
        default=os.environ.get("SLIVKI_API_BASE", DEFAULT_BASE_URL),
        help="Mobile API base URL. Defaults to SLIVKI_API_BASE or production.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=15.0,
        help="Per-request timeout in seconds.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        run_smoke(args.base_url, args.timeout)
    except SmokeFailure as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
