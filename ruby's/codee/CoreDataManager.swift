import UIKit
import CoreData

// MARK: - CoreDataManager
final class CoreDataManager {

    // MARK: - Singleton
    static let shared = CoreDataManager()
    private init() {}

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PurchasePendingDB") // xcdatamodeld name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ CoreData load error: \(error)")
            }
        }
        return container
    }()

    // MARK: - Context
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ CoreData save error:", error)
            }
        }
    }
}

// MARK: - CREATE (APPEND)
extension CoreDataManager {

    /// Always creates a NEW user (array append behavior)
    func saveUser(email: String, status: Bool) {
        let user = PurchasePendingDB(context: context)
        user.email = email
        user.status = status

        saveContext()

        logAllUsers(tag: "AFTER SAVE (APPEND)")
    }
}

// MARK: - READ
extension CoreDataManager {

    /// Fetch first user (if needed)
    func fetchUser() -> PurchasePendingDB? {
        let request: NSFetchRequest<PurchasePendingDB> = PurchasePendingDB.fetchRequest()
        return try? context.fetch(request).first
    }

    /// Fetch all users
    func fetchAllUsers() -> [PurchasePendingDB] {
        let request: NSFetchRequest<PurchasePendingDB> = PurchasePendingDB.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - UPDATE
extension CoreDataManager {

    /// Update status of a specific user
    func updateUser(user: PurchasePendingDB, status: Bool) {
        user.status = status
        saveContext()

        logAllUsers(tag: "AFTER UPDATE")
    }
}

// MARK: - DELETE
extension CoreDataManager {

    /// Delete a specific user
    func deleteUser(_ user: PurchasePendingDB) {
        context.delete(user)
        saveContext()

        logAllUsers(tag: "AFTER DELETE")
    }

    /// Delete ALL users
    func clearAllUsers() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "PurchasePendingDB" // 🔥 explicit entity name
        )

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                into: [context]
            )

            saveContext()
            logAllUsers(tag: "AFTER CLEAR ALL")

        } catch {
            print("❌ Batch delete failed:", error)
        }
    }

}

// MARK: - DEBUG LOGGING
extension CoreDataManager {

    /// Prints all stored Core Data users
    func logAllUsers(tag: String = "LOG") {
        let request: NSFetchRequest<PurchasePendingDB> = PurchasePendingDB.fetchRequest()

        do {
            let users = try context.fetch(request)

            print("\n========== CORE DATA \(tag) ==========")
            print("Total Users:", users.count)

            for (index, user) in users.enumerated() {
                print("""
                [\(index)]
                Email  : \(user.email ?? "nil")
                Status : \(user.status)
                ----------------------------
                """)
            }

            if users.isEmpty {
                print("⚠️ No users found")
            }

            print("=====================================\n")

        } catch {
            print("❌ CoreData fetch error:", error)
        }
    }
}

extension CoreDataManager {

    /// Returns true if ANY user has status == true
    /// Also prints ALL stored users for debugging
    func isAnyUserStatusTrue() -> Bool {

        // 🔹 1. Print ALL stored data
        let allRequest: NSFetchRequest<PurchasePendingDB> = PurchasePendingDB.fetchRequest()

        do {
            let allUsers = try context.fetch(allRequest)

            print("\n========== CORE DATA CHECK ==========")
            print("Total Users:", allUsers.count)

            for (index, user) in allUsers.enumerated() {
                print("""
                [\(index)]
                Email  : \(user.email ?? "nil")
                Status : \(user.status)
                ----------------------------
                """)
            }

            if allUsers.isEmpty {
                print("⚠️ No users stored")
            }

        } catch {
            print("❌ CORE_DATA >>> fetch all error:", error)
        }

        // 🔹 2. Optimized check for ANY status == true
        let checkRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "PurchasePendingDB"
        )

        checkRequest.predicate = NSPredicate(format: "status == YES")
        checkRequest.fetchLimit = 1
        checkRequest.includesPropertyValues = false

        do {
            let count = try context.count(for: checkRequest)

            if count > 0 {
                print("✅ CORE_DATA >>> YES, found TRUE status")
                print("=====================================\n")
                return true
            } else {
                print("⚠️ CORE_DATA >>> NO true status found")
                print("=====================================\n")
                return false
            }

        } catch {
            print("❌ CORE_DATA >>> count error:", error)
            print("=====================================\n")
            return false
        }
    }
}

extension CoreDataManager {

    /// Returns true if the given email has status == true
    /// - Parameter checkingID: email id to check
    func isStatusTrue(for checkingID: String) -> Bool {

        let request = NSFetchRequest<NSFetchRequestResult>(
            entityName: "PurchasePendingDB"
        )

        request.predicate = NSPredicate(
            format: "email == %@ AND status == YES",
            checkingID
        )
        request.fetchLimit = 1
        request.includesPropertyValues = false

        do {
            let count = try context.count(for: request)

            if count > 0 {
                print("✅ CORE_DATA >>> TRUE status found for email:", checkingID)
                return true
            } else {
                print("⚠️ CORE_DATA >>> FALSE status for email:", checkingID)
                return false
            }

        } catch {
            print("❌ CORE_DATA >>> email status check error:", error)
            return false
        }
    }
}
