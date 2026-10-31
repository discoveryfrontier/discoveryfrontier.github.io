# discoveryfrontier.github.io

Source for [discoveryfrontier.org](https://discoveryfrontier.org). A Jekyll site built by GitHub Pages from `main`; the `CNAME` file sets the custom domain (DNS is on Cloudflare).

## Editing content

Most changes are edits to a data file; the templates read from them.

| File | What it holds |
|---|---|
| `_data/papers.yml` | Every paper on the homepage, `/research/` and `/team/`, with its authors in paper order and a one-sentence `tldr`. `stage` must be a key from `stages.yml`. |
| `_data/stages.yml` | Research-loop stages, in display order, with each stage's accent colour. |
| `_data/team.yml` | Contacts (name, affiliation, email) listed on `/team/`. |
| `_data/upcoming.yml` | "Coming soon" rows on the homepage. Only `name` and `status`; nothing about unpublished work. |

## Adding a paper's card image

Each card on `/research/` shows the paper's first page as a 320 px-wide JPEG. With poppler installed:

```bash
pdftoppm -f 1 -l 1 -scale-to-x 320 -scale-to-y -1 -jpeg -jpegopt quality=78 -singlefile paper.pdf assets/img/papers/<id>
```

## Preview locally

```bash
bundle install
bundle exec jekyll serve
```

Then open http://localhost:4000.

## Checks

Every push runs `.github/workflows/check.yml`: the data validator, a Jekyll build, and an internal link check. To run them locally:

```bash
bundle exec ruby scripts/validate_data.rb
bundle exec jekyll build
bundle exec htmlproofer ./_site --disable-external
```

Running the workflow by hand (Actions → Check site → Run workflow) also checks external links.
