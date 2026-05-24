# OpenEFB landing page

Static site for **openefb.quartermint.com**. Deployed to Cloudflare Pages.

## Files

```
web/
├── index.html              Pretext-native landing page
├── pretext.js              Inlined text-layout engine (ES module)
├── variant-A-paper-day.webp
├── variant-B-dark-dusk.webp
├── variant-C-red-night.webp
├── _headers                Cloudflare cache + security headers
├── wrangler.jsonc          Cloudflare Pages config
├── deploy.sh               One-shot deploy script
└── README.md               This file
```

## Local preview

```bash
cd web
python3 -m http.server 8765
# Open http://localhost:8765
```

## First-time Cloudflare setup

```bash
# 1. Log in to Cloudflare (one time per machine)
wrangler login

# 2. Deploy — creates the Pages project on first run
./deploy.sh

# 3. After first deploy, in the Cloudflare dashboard:
#    Pages → openefb → Custom domains → Add → openefb.quartermint.com
#    (Cloudflare auto-provisions the cert if DNS is on Cloudflare)
```

## Subsequent deploys

```bash
./deploy.sh
```

That's it. Wrangler uploads only changed files; redeploys take 5-10 seconds.

## Updating mockups

Source PNGs live at `~/.gstack/projects/quartermint-openefb/designs/design-system-20260523/`.
After updating any variant, re-encode to WebP:

```bash
SRC=~/.gstack/projects/quartermint-openefb/designs/design-system-20260523
for v in variant-A-paper-day variant-B-dark-dusk variant-C-red-night; do
  cwebp -q 82 -m 6 "$SRC/$v.png" -o "$v.webp"
done
```

Then `./deploy.sh`.

## Updating the design system

Source-of-truth for visual tokens is `/Users/ryanstern/openefb/DESIGN.md`.
When DESIGN.md changes, sync the CSS custom properties in `index.html` (search for
`PAPER-DAY MODE`, `DARK-DUSK MODE`, `RED-NIGHT MODE`).
