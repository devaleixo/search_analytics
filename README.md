# Helpjuice Realtime Search Analytics

This is a solution for the Full-Stack Internship test provided by Helpjuice. The objective is to track user input in real-time, store relevant search queries individually per user (based on IP), and display analytics and trends based on those queries.

---

## 🧠 Project Goal

- Capture and store user search input in real time.
- Ensure that stored queries are meaningful and non-redundant.
- Keep search records separated by user (IP-based).
- Provide an analytics interface that summarizes trends and insights about user behavior.

---

## ⚙️ Tech Stack

- **Ruby on Rails 8**
- **PostgreSQL**
- **HTML + Vanilla JavaScript** (inlined for simplicity and better code reuse)

---

## 📁 Project Structure

### Models

- `UserSearch` is the model responsible for storing each search query.
- Includes logic to:
  - **Clean pyramid-like input** (incremental typing like "test", "test case", "test case today").
  - **Remove duplicates**, keeping only the most recent occurrence of identical queries.

### Controllers

- `SearchQueriesController` handles:
  - Saving each new query from the frontend.
  - Running pyramid and duplicate cleanup logic right after insertion.
  - Aggregating and returning search analytics.
  - Responding with autocomplete suggestions.

### JavaScript

- Written directly inside the HTML views for fast integration.
- Captures every keystroke (`input` event) and sends the query to the backend via `fetch()` POST.
- Supports autocomplete functionality using JSON responses.

---

## 🧹 Pyramid & Duplicate Filtering

To keep the database clean and focused:

### ✅ `clean_pyramid_queries_for(ip_address)`

- Keeps only the longest and most complete version of a typing session.
- For example:
  - `"how to"`
  - `"how to install"`
  - `"how to install ruby"`
  - Only `"how to install ruby"` is kept.

### ✅ `remove_duplicates_for(ip_address)`

- Ensures that exact duplicates are removed.
- Keeps only the latest occurrence of repeated identical queries.

Both methods are run every time a new search is created.

---

## 📊 Analytics

Analytics are exposed through a dedicated action and include:

- **Most searched terms**
- **Searches in the last 24h**
- **Daily search volume (past 7 days)**
- **Popular long phrases**
- **Unique users (by IP)**
- **Total search count**

---

## 🚀 How to Run Locally

```bash
git clone https://github.com/your-username/helpjuice-search-analytics.git
cd helpjuice-search-analytics
bundle install
rails db:create db:migrate
rails server
