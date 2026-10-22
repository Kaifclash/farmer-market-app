# Farmer Market

Farmer Market is a Flutter agricultural marketplace demo. Accounts, catalog,
cart, addresses, wishlist and orders are stored locally on the current device
with `shared_preferences`; the app does not connect to Firebase or synchronize
data between devices.

## Run

```powershell
flutter pub get
flutter run
```

No cloud project, keys or `--dart-define` values are required. Run validation:

```powershell
flutter analyze
flutter test
```

## Local features

- Customer and seller registration, sign-in and persisted session. A local
  demo admin account is seeded automatically; registration cannot create
  additional admin accounts.
- Admin dashboard with seller application approval/rejection, account
  suspension, product/category management and order overview.
- Product catalog browsing, search, category and price filtering, and paging.
- Seller product listings with edit, delete, stock and availability controls.
- Customer wishlist, cart quantities, saved delivery addresses and Cash on
  Delivery checkout.
- Order history, eligible cancellation with stock restoration, seller order
  status updates and delivered-order reviews.
- Orders retain product price and quantity snapshots.

New accounts, products, carts, orders and saved addresses remain on the device
where they were created. Default product categories are supplied, but no demo
inventory is shown as real stock.

## Limitations

Local preferences are not encrypted or protected by a trusted backend. Local
records do not sync between users/devices, and local stock/order updates cannot
provide server-side transaction guarantees. Do not use local roles for
production access control, real orders, payments or sensitive personal data.

Seller accounts start pending. Sign in to the local admin using
`admin@farmermarket.local` / `admin123`, open the **Sellers** tab, then approve
or reject applications. The seeded demo account and its permissions are stored
locally and are not secure; anyone with access to this device/app data can
modify local records. This is for local testing only, not production.

Password reset via email, cloud image uploads, push notifications, complaints
and cross-device marketplace behavior require a backend and are not provided.
