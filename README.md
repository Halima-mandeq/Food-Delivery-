# Food Delivery Project

This project is a full food delivery system built with a Flutter frontend and a PHP/MySQL backend. It is designed to support three different user experiences inside one product:

- Customer app for browsing restaurants, adding items to cart, paying, and tracking orders
- Admin dashboard for managing products, users, orders, restaurants, and reports
- Delivery dashboard for delivery-partner status, earnings, activity, and profile views

The project is structured as a practical end-to-end application rather than a static UI demo. The frontend talks directly to PHP API endpoints, and the backend persists data in MySQL through XAMPP-style local hosting.

## What This Project Is

At its core, this is a role-based food ordering platform.

Customers can:

- create an account and sign in
- browse featured restaurants and promotions
- filter by category and search for food
- open restaurant details and menu items
- customize items, add notes, and manage a cart
- choose a payment method
- place an order
- track current and previous orders
- update profile information

Admins can:

- log in to a dedicated admin dashboard
- view overview metrics and recent orders
- manage products and availability
- add or edit products with project images or uploaded images
- review user accounts
- inspect order activity
- view reports such as revenue trends, product categories, and top vendors

Delivery users can:

- log in with the delivery role
- access a dedicated delivery dashboard
- view earnings, trip history, activity, and profile sections
- switch between dashboard tabs optimized for delivery operations

## What Makes This Project Strong

Some of the strongest parts of this project are:

- Role-based experience: one codebase serves customers, admins, and delivery partners with separate dashboards and flows.
- End-to-end ordering: the system is not just a UI. It supports catalog browsing, cart building, checkout, order persistence, and order history.
- Real backend integration: Flutter services call PHP endpoints that read and write MySQL data.
- Admin tooling: the admin area goes beyond CRUD and includes analytics, operational summaries, and reporting screens.
- Flexible content: categories, promotions, products, menu items, and orders are driven by backend data instead of only hardcoded UI.
- Profile management: customers can now update full name, email, phone number, and password from the app.
- Runtime schema support: the backend contains helper logic that can add missing order-related columns and ensure role compatibility, which makes the app more resilient during local development.

## Technology Stack

### Frontend

- Flutter
- Dart
- Material Design widgets
- `http` for API communication
- `image_picker` for image handling in admin product workflows
- `url_launcher` for actions such as opening the EVC dialer

### Backend

- PHP
- PDO for database access
- MySQL
- XAMPP-style local hosting

### Data and Assets

- SQL schema in `backend/schema.sql`
- frontend assets in `frontend/images/`
- uploaded backend assets in `backend/uploads/`

## Project Structure

```text
food delivery/
|-- backend/
|   |-- api/          # PHP API endpoints
|   |-- config/       # DB connection and support helpers
|   |-- uploads/      # Uploaded product images
|   `-- schema.sql    # Database schema and seed data
|-- frontend/
|   |-- lib/
|   |   |-- core/     # App config and theme
|   |   `-- features/ # Auth, home, admin, order, profile flows
|   |-- images/       # App image assets
|   `-- pubspec.yaml  # Flutter dependencies and assets
`-- README.md
```

## Frontend Architecture

The Flutter app starts from `frontend/lib/main.dart` and launches the onboarding screen first. The codebase is organized by feature so each part of the application keeps its models, services, pages, and widgets together.

### Main frontend areas

- `core/config/app_config.dart`
  - handles backend base URL selection
  - uses `127.0.0.1` for web
  - uses `10.0.2.2` for Android emulator
  - supports overriding with `--dart-define=API_BASE_URL=...`

- `core/theme/app_theme.dart`
  - defines the app theme, brand colors, and general styling

- `features/auth/`
  - onboarding
  - login
  - sign up
  - user model and auth service

- `features/home/`
  - customer home page
  - restaurant details
  - item details
  - cart
  - checkout
  - order status/history
  - customer profile
  - profile edit page
  - product and order services

- `features/admin/`
  - admin dashboard
  - product management
  - add/edit product screen
  - admin users, orders, restaurants, and reports services

### Customer flow

The main customer journey looks like this:

1. Onboarding
2. Sign up or login
3. Browse restaurants and promotional content on the home page
4. Open a restaurant
5. Open an item and customize options
6. Add to cart
7. Review cart totals
8. Continue to checkout
9. Pay with Mastercard or EVC
10. Place the order
11. Track order status and view order history

### Payment experience

The checkout flow supports two payment choices in the current frontend:

- Mastercard
- EVC

The EVC flow includes a USSD dialer-based interaction through `url_launcher`, which is a useful local-market detail in this project.

### Role-based routing

After login, the app routes based on the user role:

- `user` -> customer `HomePage`
- `admin` -> `AdminDashboard`
- `delivery` -> `DeliveryDashboardPage`

That role-based redirection is one of the most important architectural ideas in the project.

## Backend Architecture

The backend is a lightweight PHP API that exposes multiple endpoints under `backend/api/`. Each endpoint handles one area of application behavior, such as authentication, product retrieval, order placement, admin statistics, or profile updates.

### Backend responsibilities

- authenticate users
- register new users
- return product catalogs and menu items
- return promotions and categories
- place orders and save order items
- fetch order history for customers
- expose admin statistics, users, restaurants, orders, and reports
- add, update, and delete products
- update customer profile information

### Configuration files

- `backend/config/db.php`
  - creates the PDO connection to MySQL
  - uses the local database `food_delivery_db`

- `backend/config/auth_roles.php`
  - ensures the `users.role` column supports `user`, `admin`, and `delivery`
  - creates or preserves the default delivery account

- `backend/config/order_support.php`
  - ensures order tables and order-related columns exist
  - helps runtime compatibility for order features
  - provides helper functions for payment normalization and fetching user orders

This support-layer approach is valuable because it reduces the chance of local environment breakage when the schema evolves.

## Database Design

The main schema lives in `backend/schema.sql`.

### Core tables

- `users`
  - stores full name, email, phone number, password hash, role, timestamps

- `categories`
  - stores menu/product category names and display order

- `products`
  - acts like the restaurant/product catalog in this project
  - includes name, description, price, category, image, rating, delivery info, and availability

- `menu_items`
  - stores items inside a restaurant

- `home_promotions`
  - stores banners and promotional cards shown on the home page

- `orders`
  - stores order totals, payment method, address, status, delivery timing, and restaurant context

- `order_items`
  - stores the individual items inside each order, including quantity and price

### Seed data

The schema also seeds:

- default admin account
- default delivery account
- starter categories
- sample restaurants/products
- sample menu items
- home promotion data
- initial order records for dashboard stats

## API Overview

The backend exposes the following main endpoints.

### Authentication

- `login.php`
- `register.php`
- `update_profile.php`

### Customer catalog and home content

- `get_products.php`
- `get_categories.php`
- `get_menu_items.php`
- `get_home_promotions.php`

### Orders

- `place_order.php`
- `get_user_orders.php`

### Admin

- `get_admin_stats.php`
- `get_admin_orders.php`
- `get_admin_users.php`
- `get_admin_restaurants.php`
- `get_admin_reports.php`
- `add_product.php`
- `update_product.php`
- `delete_product.php`

### Utility

- `test_connection.php`
- `fix_admin.php`

## How The System Works End To End

### 1. Authentication

Users register or log in through Flutter forms. The frontend sends JSON to PHP authentication endpoints. On successful login, the backend returns user details including the role. The frontend then opens the correct dashboard for that role.

### 2. Home content loading

The customer home page loads:

- categories
- promotions
- featured products/restaurants
- user orders

This data is fetched through dedicated Flutter services and displayed in a mobile-first experience with filtering, search, and promotional cards.

### 3. Restaurant and item browsing

Customers open a restaurant, fetch its menu items, then open item details. The item detail page supports option pricing, quantity changes, notes, and cart integration.

### 4. Checkout and order creation

At checkout, the app calculates subtotal, tax, delivery fee, and total. The frontend submits a structured order payload to `place_order.php`, including:

- user ID
- restaurant information
- delivery address
- payment method
- selected cart items
- item options
- quantities

The backend validates the data, stores the order, stores all line items, and returns the newly created order back to Flutter.

### 5. Order tracking

Customer order history is loaded from `get_user_orders.php`. The app then renders active orders and past orders in a dedicated order screen.

### 6. Admin operations

The admin dashboard aggregates:

- statistics
- recent orders
- product records
- restaurant data
- users
- reports

This gives the project a more complete product-management layer than a simple student CRUD app.

## Key Frontend Screens

### Authentication

- Onboarding page
- Login page
- Sign up page

### Customer

- Home page
- Restaurant details page
- Item details page
- Cart page
- Checkout page
- Order status page
- Customer profile tab
- Profile info page

### Delivery

- Delivery dashboard page

### Admin

- Admin dashboard
- Add product page
- Manage products page

## Key Admin Features

The admin experience is one of the best parts of the project.

It includes:

- dashboard metrics
- revenue overview
- recent order feed
- user management
- order monitoring
- product catalog management
- restaurant/product filtering
- reporting with revenue trends
- category breakdowns
- top vendor summaries

It also supports product image selection from bundled frontend assets and image uploads to backend storage.

## Key Customer Features

- onboarding and account flow
- restaurant discovery
- search and category filtering
- promotional banners and offers
- cart quantity updates
- item customization with extra pricing
- delivery address handling
- Mastercard and EVC payment flows
- live and historical order views
- editable customer profile

## Key Delivery Features

The delivery dashboard currently focuses on a polished role-specific UI experience and dashboard summaries, including:

- online/offline state
- earnings summary
- active delivery card
- recent activity
- earnings/history/profile tabs

This gives the project room to grow into deeper delivery workflow logic later.

## Configuration

Backend URL configuration is handled in `frontend/lib/core/config/app_config.dart`.

Default behavior:

- Web uses `http://127.0.0.1/food%20delivery/backend/api`
- Android emulator uses `http://10.0.2.2/food%20delivery/backend/api`

You can override it at runtime:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_HOST/food%20delivery/backend/api
```

## Local Setup

### Requirements

- Flutter SDK
- Dart SDK
- PHP
- MySQL
- XAMPP or equivalent Apache/MySQL local server

### Backend setup

1. Put the project inside your web server directory, such as `htdocs`.
2. Start Apache and MySQL from XAMPP.
3. Create/import the database using `backend/schema.sql`.
4. Make sure the backend is reachable under:

```text
http://localhost/food%20delivery/backend/api
```

### Frontend setup

1. Open the `frontend/` folder.
2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

For web:

```bash
flutter run -d chrome
```

For a different backend host:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_HOST/food%20delivery/backend/api
```

## Default Accounts

The database seed includes these default role accounts:

- Admin
  - Email: `admin@gmail.com`
  - Password: `admin123`

- Delivery
  - Email: `delivery@wagba.com`
  - Password: `delivery123`

Customer accounts are created through the sign-up flow.

## Important Notes

- This project currently uses role-based routing from login response data.
- The backend is API-style PHP and does not use a large framework such as Laravel.
- Product images can come from built-in frontend assets or backend uploads.
- Order support and role support include schema-compatibility helpers in PHP.
- The app is designed primarily for local development and demonstration, but the structure is strong enough for future expansion.

## Future Improvements

Some good next steps for future versions would be:

- token-based authentication
- stronger authorization checks per role on backend endpoints
- real delivery assignment logic
- live order status updates with websockets or polling improvements
- payment gateway integration for production card processing
- more complete profile management for admin and delivery users
- automated tests for frontend services and backend API endpoints
- deployment configuration for production hosting

## Final Summary

This project is a complete multi-role food delivery application with a modern Flutter interface and a functional PHP/MySQL backend. It covers much more than simple screen design: it includes real data flow, user roles, ordering logic, admin reporting, product management, and profile editing.

The biggest value of this project is that it shows full-stack thinking:

- mobile/frontend UX
- backend API design
- relational database design
- role-based product behavior
- operational dashboards

That combination is what makes this project feel like a real system instead of just a collection of pages.
