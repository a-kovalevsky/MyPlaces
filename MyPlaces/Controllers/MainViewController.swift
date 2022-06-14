//
//  MainViewController.swift
//  MyPlaces
//
//  Created by andrew on 11.05.22.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)//выбирая тут нил мы говорим что для отображения результатов будем использовать вью в котором отображается основной контент
    private var places: Results<Place>!//results возвращает запрашиваемые объекты,отображает состояние хранилище в текущем потоке в реальном времени,это массив объектаов типa <>
    private var filteredPlaces: Results<Place>! //массив для хранения отфильтрованных записей
    private var ascendindSorted = true //для сортировки в обратном порядке
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else {return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {//буцдет возвращать тру когда поисковый запрос активирован
        return searchController.isActive && !searchBarIsEmpty //когда searchbar будет !false и первый активироан(true)
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    // let restaurantNames = ["Burger Heroes","Kitchen","Bonsai","Дастархан","Индокитай","X.O","Балкан Гриль","Sherlock Holmes","Speak Easy","Morris Pub","Вкусные истории","Классик","Love&Life","Шок","Бочка"]
   //var places = Place.getPlaces() раньше принимали метод,который возвращает массив плэйс,сейчас есть база данных
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        places = realm.objects(Place.self)//инициализация объекта places !!
        
        //Setup Search controller
        searchController.searchResultsUpdater = self //получателем инфы об изменении текста будет мэйн класс
        searchController.obscuresBackgroundDuringPresentation = false //позволяет взаимодействовать с отображаемым контентом
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController //интегрируем строку поиска в навигейшн бар
        definesPresentationContext = true //отпускает строку поиска при переходе на новый экран
        navigationItem.hidesSearchBarWhenScrolling = true
        
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count //в случае поиска возвращает количество закинутого в массив отфильтрованного хлама по поиску
        }
        return places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell //если ячейка кастомная,то ее надо кастить для созданногно класа нового Customtableviewcell,по умолчанию cell является объектом tableviewcell
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        //делаем более читабельно,чтоб не использовать places[indexPath.row].location
       // let place = places[indexPath.row]

        cell.nameLabel.text = place.name //обращаемся по индекспас к конкретному объекту массива и после через точку к свойсвту объекта из массива
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.ImageOfPlace.image = UIImage(data: place.imageData!)
        cell.cosmosView.rating = place.rating

       
        return cell
    }

//настройка высоты строки через интерфейс билдер была
    
    //  MARK: Table view delegate
     func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         tableView.deselectRow(at: indexPath, animated: true)
        let place = places[indexPath.row]//объект для удаления по индекс пафу
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (_,_,_) in
            StorageManager.deleteObject(place) //вызываем метод подставляем плэйс и удаляем из базы
            tableView.deleteRows(at: [indexPath], with: .automatic) //удаляем из тэйбл вью
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        return swipeActions
    }
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            //при тапе на ячейки передаем в нью плэйс объект нынешний выбранный из таблицы
            guard let indexPath = tableView.indexPathForSelectedRow else {return}//извлекаем индекс паф текущей ячейки
            //let place = places[indexPath.row] //имея индекс выбранный извлекаем из массива places нужный объект
            
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            
            let newPlaceVC = segue.destination as! NewPlaceViewController//теперь создаем экземпляр нью плэйс вью контроллера
            newPlaceVC.currentPlace = place //приравниваем к свойству другого вью контроллера 
        }
    }
    @IBAction func unwindSegue (_ segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceViewController else {return}//кастим до нью плэйс через сорс и будем приравнивать принимаемые значения в дальнейший массив модели ,либо еще как-то
        newPlaceVC.savePlace() //тут вызываем метод,который передает вводимые поля в нью плэйс в экземпляр структур(модели данных),этот метод сработает еще  перед закрытием вью контролера
    
        tableView.reloadData() 
    }
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
       sorting()
    }
    @IBAction func reversedSorting(_ sender: UIBarButtonItem) {
        ascendindSorted.toggle()//меняет значение на противположное для сортировки при нажатии и снизу условие длясмены картинки
        if ascendindSorted == true {
            reversedSortingButton.image = UIImage(named: "AZ")
        } else {
            reversedSortingButton.image = UIImage(named: "ZA")
        }
        sorting()
    }
    private func sorting() {  //объявим отдельный метод для сортировки
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendindSorted)//сортировка в зависимости от ascending
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendindSorted)//тоесть сортируется по кейпас и в зависимости от  ascendingSorted будет сортироваться также по возрастанию
        }
        tableView.reloadData()
    }
}
extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {//вызывается по тапам и любому редактиованию
        filterContentForSearchText(searchController.searchBar.text!)
    }
    private func filterContentForSearchText(_ searchText: String){
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@",searchText,searchText)//выполняем поиск по полям нэйм и локейшн вне зависимости от регистра и параметрам search text
        tableView.reloadData()
    }
    
}
