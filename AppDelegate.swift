import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Demander la permission pour envoyer des notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notifications autorisées")
            } else {
                print("❌ Autorisation refusée")
            }
        }
        
        // Définir le délégué des notifications
        UNUserNotificationCenter.current().delegate = self

        // 📌 Ajouter les notifications ici
        scheduleDailyPokemonNotification()  // ✅ Notification quotidienne
        sendTestNotification()  // ✅ Notification test

        return true
    }

    // ✅ Planifie une notification quotidienne
    func scheduleDailyPokemonNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌟 Pokémon du Jour !"
        content.body = "Viens découvrir un Pokémon surprise !"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 10  // ⏰ Notification à 10h chaque jour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyPokemon", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur notification quotidienne : \(error.localizedDescription)")
            } else {
                print("✅ Notification quotidienne programmée")
            }
        }
    }

    // ✅ Envoie une notification test après 5 secondes
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚀 Notification Test"
        content.body = "Ceci est une notification test !"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur notification test : \(error.localizedDescription)")
            } else {
                print("✅ Notification test envoyée")
            }
        }
    }

    // ✅ Afficher la notification même si l'app est en premier plan
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}


