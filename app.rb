require "functions_framework"
require "json"
require "rest_client"
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/array/grouping'

FunctionsFramework.http "perform" do |request|
  url = request.params["url"]
  api_url = 'https://www.page2api.com/api/v1/scrape'
  api_key = request.params["api_key"]
  pages_per_batch = (request.params["pages_per_batch"] || 10).to_i
  max_pages = (request.params["max_pages"] || 20).to_i
  concurrency = (request.params["concurrency"] || 1).to_i
  reviews = []

  payload = {
    wait_for: "[data-region=review]",
    real_browser: true,
    premium_proxy: "us",
    raw: true,
    api_key: api_key,
    parse: {
      reviews: [
        {
          url: ".wt-grid a >> href",
          author: ".shop2-review-attribution a >> text",
          rating: ".stars-svg input[name=initial-rating] >> value",
          _parent: "[data-region=review]",
          content: ".wt-text-gray >> text",
          author_date: ".shop2-review-attribution >> text",
          product_name: ".wt-grid a >> text"
        }
      ]
    }
  }

  response = RestClient::Request.execute(
    method: :post,
    payload: payload.deep_merge({
      url: url,
      parse: {
        pages: "js >> TWF0aC5jZWlsKHBhcnNlSW50KGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3IoIi5yZXZpZXdzLXRvdGFsIGRpdjpsYXN0LW9mLXR5cGUiKT8uaW5uZXJUZXh0Py5yZXBsYWNlKCcoJywgJycpPy5yZXBsYWNlKCcpJywgJycpIHx8IDEpIC8gMTQp",
      }
    }).to_json,
    url: api_url,
    headers: { "Content-type" => "application/json" },
  ).body

  data = JSON.parse(response)

  reviews += data['reviews']
  pages = data['pages'].to_i

  return reviews.to_json if [0, 1].include?(pages)
  return reviews.to_json if max_pages == 1

  urls = []

  generated_pages = (1..[pages, max_pages].min).to_a[1..-1]

  generated_pages.each do |page|
    urls << "#{url}?ref=pagination&page=#{page}"
  end

  urls.in_groups_of(pages_per_batch, false) do |group|
    response = RestClient::Request.execute(
      method: :post,
      payload: payload.deep_merge({
        batch: {
          urls: group,
          merge_results: true,
          concurrency: concurrency
        }
      }).to_json,
      url: api_url,
      headers: { "Content-type" => "application/json" },
    ).body

    data = JSON.parse(response)

    reviews += data['reviews']
  end

  reviews.to_json
end