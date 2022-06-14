//
//  NewPlaceViewController.swift
//  MyPlaces
//
//  Created by andrew on 12.05.22.
//

import UIKit

class NewPlaceViewController: UITableViewController {
    
   // var newPlace = Place()//теость по факту сделав модель данных(структуру),можем объявить тут и в любом методе и как угодно передпапть значения из текст филдов
    var currentPlace: Place! //для перехода  от ячейки передаем сюда тип плейс
    var imageIsChanged = false

    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!//чтоб получить доступ к рейтинг создаем этот аутлет

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))//когда ниже ячеек разлинееная по умолчанию таблица,не оч ,поэтому мы и присваиваем футеры таблицы сам вью
        saveButton.isEnabled = false //отключаем по умолчанию
        placeName.addTarget(self, action: #selector(textFieldChanges), for: .editingChanged)//каждый раз при редактировании будет срабатывать селектор с функцией objc,будет следить за заполненностоью поля,нижу рнеализуем метод в делегате текстфилд
        setupEditScreen()
        
       
        
    }
    
    
// MARK: Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 { //вызываем метод,который сраьатывает перед выделением ячейки,если выбранная ячейка ее номер по индекс пафу будет нулю,тоесть первая ячейка,то тогда мы вызываем меню для выбора картинки ,которое реализуем чернз алерт контроллер и алерт экшены, если нет то скрывается клавиатура по тапу на ячейку
            
            let cameraIcon = UIImage(named: "camera")
            let photoIcon = UIImage(named: "photo")
            
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let camera = UIAlertAction (title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")//распололожение алерта слева
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")//распололожение алерта слева
            	
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(camera)//под одному добавляем в контроллер экшены для алерта,не забываем прописывать логику
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            //вызываем алерт контроллер
            present(actionSheet,animated: true)//без completion
        } else {
            view.endEditing(true)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier,
              let mapVC = segue.destination as? MapViewController else {return}
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self
        
        if identifier == "ShowPlace" {
            mapVC.place.name = placeName.text!
            mapVC.place.location = placeLocation.text
            mapVC.place.type = placeType.text
            mapVC.place.imageData = placeImage.image?.pngData()
        }
        
    }
    
    func savePlace () {
        var image: UIImage?
        
        if imageIsChanged {
            image = placeImage.image
        } else {
            image = UIImage(named: "imagePlaceholder")
        }
        
        let imageData = image?.pngData()
        
        let newPlace = Place(name: placeName.text!, location: placeLocation.text, type: placeType.text, imageData: imageData, rating: Double(ratingControl.rating))
        //добавляем редактируемый карэнтплэйс в базу для изменения
        
        if currentPlace != nil {
            try! realm.write {//соответсвенно меняем на новые значения приходящие при редактировании
                currentPlace?.name = newPlace.name
                currentPlace?.type = newPlace.type
                currentPlace?.location = newPlace.location
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            //сохраняем объект в базу данных
            StorageManager.saveObject(newPlace)
        }
        
    }//при нажатии кнопки сэйв вызываем етот метод передаем значение заполненных полей в свойства модели,когторую объявляем тут в свойствах
    
    private func setupEditScreen() {
        if currentPlace != nil {//должна же ячейка что-то содержать
            setupNavigationBar()
            imageIsChanged = true
            
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else {return}
            
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill
            placeName.text = currentPlace?.name
            placeType.text = currentPlace?.type
            placeLocation.text = currentPlace?.location
            ratingControl.rating = Int(currentPlace.rating)
                        
        }
    }
    
    private func setupNavigationBar() {//метод для настройки при редактировании,важно запускать из метода когда сетапедитскрин
        if let topItem = navigationController?.navigationBar.topItem{
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)//убрали заголовок
        }//меняем заголовок кнопки возврата,но она может вернуть нил,так что раскрывваем опшинал
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButton.isEnabled = true
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }//мы убрали анвинд сегвей с этого контроллера для кнопки кэнсэл,поэтому взяли айбиэкшн для того чтобы вызвать метод дисмисс
    
}
// MARK: Text field delegate
extension NewPlaceViewController: UITextFieldDelegate {
    //через функцию которая есть в делегейт сркываем клавиатуру
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    //советуют делать скрытие клавиатуры через обзервер,но не в этот раз так как по тапу на первую ячйку будем выбирать фотку для будущего заведения
    //определяем выделенную ячейку,если это первая ячейка =меню,либо скрытие клавиатуры
}
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
    if UIImagePickerController.isSourceTypeAvailable(source) { //проверка на достпуность пикера тип библиотека чи камера
        let imagePicker = UIImagePickerController()//объект имидж пикера
        imagePicker.delegate = self
        imagePicker.allowsEditing = true//позволит редактировать изображения
        imagePicker.sourceType = source //присваиваем занчение сорс тайпу приходящее значение
        present(imagePicker,animated: true)//так как имедж пикер вью контроллер,показываем его через презент
        }
    }
    //подключаем имедж пикерконтроллер делегат
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            placeImage.image = info[.editedImage] as? UIImage //разрешили пользователю редактиовать элоус едитинг,тут присваиваем это изображение аутлету
            //настройка имедж вью
            placeImage.contentMode = .scaleToFill
            placeImage.clipsToBounds = true
            //потом закрываем этот вью
        
            imageIsChanged = true
        
            dismiss(animated: true)
        }
    @objc private func textFieldChanges () {
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
            
        } else {
            saveButton.isEnabled = false
        }
    }
}
extension NewPlaceViewController: MapViewControllerDelegate  {
    func getAddress(_ address: String?) {//уже содержит адрес + смотри делегат(для чего именно так?и всегда ли надо так делать?)
        placeLocation.text = address
    }
    
    
}
