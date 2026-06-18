# Firestore Database Tree (`smort-fridge`)

Generated on: 2026-06-18T02:29:15Z

```text
ROOT
├── 📁 Collection: users
│   └── 📄 Document: {userId} (User Profile)
│         ├── 🔹 name: "Ahmed"
│         ├── 🔹 email: "ahmed@example.com"
│         ├── 🔹 role: "home" // or "store"
│         ├── 🔹 createdAt: Timestamp
│         └── 🔹 updatedAt: Timestamp
│
└── 📁 Collection: fridges
    └── 📄 Document: {fridgeId} (e.g. "F001")
          ├── 🔹 name: "Kitchen Fridge"
          ├── 🔹 type: "home" // "home" or "store"
          ├── 🔹 ownerId: "{userId}" // Primary creator/admin
          │
          ├── 🔹 membersMetadata: {
          │      "{userId_1}": { "name": "Ahmed", "role": "admin" },
          │      "{userId_2}": { "name": "Mom", "role": "viewer" }
          │   }
          │
          ├── 🔹 status: "online"
          ├── 🔹 createdAt: Timestamp
          ├── 🔹 updatedAt: Timestamp
          │
          ├── 📁 Subcollection: shelves (Optional: Telemetry/Metadata per shelf)
          │     └── 📄 Document: {shelfId} (e.g. "A")
          │           ├── 🔹 name: "Top Shelf"
          │           ├── 🔹 temperature: 4.0 // Shelf-specific sensor telemetry
          │           └── 🔹 updatedAt: Timestamp
          │
          ├── 📁 Subcollection: items (Unified Inventory: both Camera & Manual items)
          │     └── 📄 Document: {itemId} (e.g. "8b78b464")
          │           ├── 🔹 name: "apple"
          │           ├── 🔹 source: "camera" // "camera" or "manual"
          │           ├── 🔹 createdAt: Timestamp
          │           ├── 🔹 updatedAt: Timestamp
          │           │
          │           │  // 📍 Solution 2: Denormalize shelf details inside the item to avoid subcollection queries
          │           ├── 🔹 shelfId: "A"
          │           ├── 🔹 shelfName: "Top Shelf"
          │           │
          │           │  // 📷 Solution 3: Split camera data and user modifications into separate namespaces
          │           ├── 🔹 detected: {
          │           │      "freshness": "fresh",
          │           │      "det_conf": 0.7502,
          │           │      "clf_conf": 0.6094,
          │           │      "first_seen": Timestamp,
          │           │      "last_seen": Timestamp
          │           │   } // (Only updated by hardware camera scans)
          │           │
          │           ├── 🔹 userOverrides: {
          │           │      "quantity": 3,
          │           │      "unit": "units",
          │           │      "category": "Produce",
          │           │      "status": "Fresh",
          │           │      "expiryDate": Timestamp,
          │           │      "notes": "Eat these first",
          │           │      "imageUrl": null,
          │           │      "createdBy": "{userId}"
          │           │   } // (Only updated by manual app inputs. Overrides camera values if present)
          │           │
          │           └── 🔹 source: "camera" // "camera" or "manual"
          │
          └── 📁 Subcollection: gas_alerts (Localized logs for this specific fridge)
                └── 📄 Document: {alertId}
                      ├── 🔹 sensor: "MQ-135"
                      ├── 🔹 alert: "spoilage_detected"
                      ├── 🔹 timestamp: Timestamp
                      │
                      │  // 📍 Solution 2: Denormalize shelf details in alerts too
                      ├── 🔹 shelfId: "A"
                      └── 🔹 shelfName: "Top Shelf"
```
