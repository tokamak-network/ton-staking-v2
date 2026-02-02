# TON Staking V3 Documentation Site

This website is built using [Docusaurus 3.9](https://docusaurus.io/), a modern static website generator.

## Features

- **Bilingual Support**: English (default) and Korean (한국어)
- **TON Staking V3 Documentation**: System specs, actor guides, function references
- **Based on**: Tokamak Economics Whitepaper V2 (December 2025)

## Installation

```bash
yarn install
```

## Local Development

### Development Mode (Hot Reload)

```bash
yarn start
```

- Runs at `http://localhost:3000`
- Hot reload enabled
- **Note**: For full i18n testing, use production mode

### Production Mode (Recommended for i18n testing)

```bash
yarn build
yarn serve
```

- Builds both English and Korean sites
- Runs at `http://localhost:3000`
- Full bilingual support

## URLs

| Language | URL |
|----------|-----|
| English (Home) | http://localhost:3000/ |
| Korean (Home) | http://localhost:3000/ko/ |
| English Docs | http://localhost:3000/docs/intro |
| Korean Docs | http://localhost:3000/ko/docs/intro |

## Project Structure

```
docs-site/
├── docs/                          # English documentation (default locale)
│   ├── 00-intro.md
│   ├── 01-system-overview.md
│   ├── 05-actors.md
│   └── ...
├── i18n/ko/                       # Korean translations
│   ├── docusaurus-plugin-content-docs/
│   │   ├── current/              # Korean document translations
│   │   │   ├── 00-intro.md
│   │   │   ├── 01-system-overview.md
│   │   │   └── ...
│   │   └── current.json          # Sidebar label translations
│   ├── docusaurus-theme-classic/
│   │   └── navbar.json           # Navbar translations
│   └── code.json                 # UI text translations
├── src/                          # Custom pages and components
├── static/                       # Static assets (images, etc.)
├── docusaurus.config.ts          # Main configuration
├── sidebars.ts                   # Sidebar structure
└── package.json
```

## i18n (Internationalization) Guide

### Adding/Updating Korean Documents

1. **Source files**: `/docs/specs-kr/*.md`
2. **Copy to i18n folder**:
   ```bash
   cp docs/specs-kr/*.md docs-site/i18n/ko/docusaurus-plugin-content-docs/current/
   ```
3. **Add frontmatter** (required for each document):
   ```yaml
   ---
   id: 05-actors
   sidebar_position: 5
   ---
   ```

### Sidebar Labels

- **English**: Defined in `sidebars.ts`
- **Korean**: Translated in `i18n/ko/docusaurus-plugin-content-docs/current.json`

### Adding New Sidebar Categories

1. Add to `sidebars.ts`:
   ```typescript
   {
     type: 'category',
     label: 'New Category',
     items: ['new-doc'],
   }
   ```

2. Add Korean translation to `i18n/ko/docusaurus-plugin-content-docs/current.json`:
   ```json
   {
     "sidebar.docsSidebar.category.New Category": {
       "message": "새 카테고리"
     }
   }
   ```

## Available Scripts

| Command | Description |
|---------|-------------|
| `yarn start` | Start development server (English only by default) |
| `yarn start:all` | Start with Korean locale |
| `yarn build` | Build production site (all locales) |
| `yarn serve` | Serve production build locally |
| `yarn clear` | Clear cache and build artifacts |
| `yarn write-translations` | Generate translation files |

## Build

```bash
yarn build
```

Generates static content into the `build` directory:
- `build/` - English site
- `build/ko/` - Korean site

## Deployment

### Using SSH:

```bash
USE_SSH=true yarn deploy
```

### Using HTTPS:

```bash
GIT_USER=<Your GitHub username> yarn deploy
```

### Environment Variables (for CI/CD):

```bash
DEPLOY_URL=https://your-domain.com
BASE_URL=/
```

## Troubleshooting

### "Page Not Found" for Korean pages

1. Ensure documents have proper frontmatter with `id` field
2. Run `yarn build` then `yarn serve` (not `yarn start`)
3. Clear cache: `yarn clear`

### Sidebar shows wrong language

1. Check `sidebars.ts` has English labels
2. Check `i18n/ko/docusaurus-plugin-content-docs/current.json` has Korean translations
3. Rebuild: `yarn build`

### Port already in use

```bash
lsof -ti:3000 | xargs kill -9
yarn serve
```

## Tech Stack

- **Docusaurus**: 3.9.2
- **React**: 19.0
- **Node.js**: >= 20.0
- **TypeScript**: 5.6

## Related Documentation

- [Docusaurus i18n Guide](https://docusaurus.io/docs/i18n/tutorial)
- [TON Staking V3 Specs](/docs/specs-kr/)
