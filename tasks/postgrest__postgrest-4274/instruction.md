The /metrics admin endpoint returns Prometheus metrics but does not include a proper `Content-Type` header in its HTTP response. Prometheus requires the text exposition format to be served with `Content-Type: text/plain; version=0.0.4`. When the header is missing or blank, Prometheus fails to scrape the target and reports an error like:

`Error scraping target: non-compliant scrape target sending blank Content-Type and no fallback_scrape_protocol specified for target`

Reproduce by running PostgREST with metrics enabled and sending an HTTP GET request to `/metrics`. The response body contains metrics, but the response headers do not include the required content type.

Update the metrics endpoint implementation so that responses from `GET /metrics` always include:

`Content-Type: text/plain; version=0.0.4`

Expected behavior: Prometheus can scrape `/metrics` successfully without requiring a reverse proxy to inject headers, and `/metrics` responses include the correct Prometheus text format content type. Actual behavior: the endpoint responds without the required `Content-Type`, causing Prometheus scraping to fail.