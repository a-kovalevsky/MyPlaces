//
//  RatingControl.swift
//  MyPlaces
//
//  Created by andrew on 25.05.22.
//

import UIKit

@IBDesignable class RatingControl: UIStackView { //ibdesignabe для того чтоб показывались изменения в сторибордах в мэйне,лагучая штука
// MARK: Properties
    var rating = 0 {
        didSet {
            updateButtonSelectionStates()
        }
    }//текущее значение рейтинга будем хранить тут
    private var ratingButtons = [UIButton]()//тут будет храниться массив кнопок для рейтинга
    @IBInspectable var starSize: CGSize = CGSize(width: 44, height: 44){
        didSet {
            setUpButtons()
        }
    }  //для добавления на интерфейс билдр,явно указываем все размеры!	
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setUpButtons()
        }
    }
    
    
// MARK: Initialization
    override init(frame: CGRect) { //инициализатор род класаа
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder) // в случае изменения инициализации в подклассе,инициализируем дополнительно родительский класс
        setUpButtons()
    }
    
// MARK: Button Action
    
    @objc func ratingButtonTapped(button: UIButton) {
        guard let index = ratingButtons.firstIndex(of: button) else {return}
        
        //сalculate rating of selected button
        let selectedRating = index + 1
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
        
        
    }
    
// MARK: Private Methods
    
    private func setUpButtons () { //метод для добавление кнопок в стэк вью
        
        for button in ratingButtons {//удаляем в случае переопределения через интерфейс билдер
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        //Load button image
        let bundle = Bundle(for: type(of: self )) //для ibsedignable и интерфейс билдер необходимо явно указать где мы берем изображения,класс бандл определяет местоположение
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 0..<starCount {
            //Create the button
            let button = UIButton()
            
            //Set the button image!!!
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)//при прикосновении
            button.setImage(highlightedStar, for: [.highlighted,.selected])
            
            // Add constraits,if false you set them for your own, also if you add your UIelement to interface builder, it became false automaticly
            button.translatesAutoresizingMaskIntoConstraints = false //отключает автомат сгенерированные автоматически констрэйты,но не влияет эта строка так как оно в стек вью и оно там автоматически отключается
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true //высота,далее возврат констант,далее активация их
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true//ширина
          
            //Setup button action
            button.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)//обычный тап по кнопке и срабатывает селектор для селф контроллера

            // Add button to stack
            addArrangedSubview(button)
            
            // Add new button to array
            ratingButtons.append(button)
        }
        updateButtonSelectionStates()//вдруг если в коде выставим рейтинг по умолчанию 
    }
    private func updateButtonSelectionStates () {
        for (index,button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
	
