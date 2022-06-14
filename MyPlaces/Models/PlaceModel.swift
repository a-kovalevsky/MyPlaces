//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by andrew on 12.05.22.
//


import RealmSwift

class Place: Object {
    
   @objc dynamic var name: String = ""
   @objc dynamic var location: String?
   @objc dynamic var type: String?
   @objc dynamic var imageData: Data? //для картинок из галереии типа UIImage
   @objc dynamic var restaurantImage: String?
   @objc dynamic var date = Date()//свойство для сортировки по дате добавления,пользователю не будет доступно
    @objc dynamic var rating: Double = 0.0
    
    
    convenience init(name:String, location: String?, type: String?, imageData: Data?,rating: Double){
        self.init()//иниц класса самого и создается по умолчанию и потом передается новые параметры???
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
    
    }
    
