# Etsy Reviews Scraper

## Install

```bash
bundle install
```

GCloud docs: https://cloud.google.com/functions/docs/create-deploy-gcloud

## Launch

```bash
bundle exec functions-framework-ruby --target perform
```

## Params

**api_key** - Page2API api key   
**url** - etsy reviews page   
**pages_per_batch** - pages per batch, default: 10   
**max_pages** -  max pages, default: 20   
**concurrency** - concurrency, default: 1   

## Test locally

```
http://localhost:8080/?url=https://www.etsy.com/shop/barwoodshop/reviews&api_key=YOUR_PAGE2API_KEY&max_pages=5
```
