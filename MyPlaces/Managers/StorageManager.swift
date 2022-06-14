//
//  StorageManager.swift
//  MyPlaces
//
//  Created by andrew on 16.05.22.
//

import RealmSwift

//создаем объект рилм,глобальной перменной

let realm = try! Realm()

class StorageManager {//модель для записи в базу по примеру есть на сайте
    
    static func saveObject (_ place: Place ) {
        try! realm.write {
            realm.add(place)
        }
    }
    static func deleteObject(_ place: Place) {//удаление из базы 
        try! realm.write {
            realm.delete(place)
        }
    }
}
