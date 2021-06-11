//
//  MyTicketsFilterHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.06.2021.
//

import UIKit

class MyTicketsFilterHeader: UIView {

    @IBOutlet weak var sortView: UIView!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var sortField: CustomTextField!
    @IBOutlet weak var filterField: CustomTextField!
    
    weak var selectionDelegate: FilterSortingSelectionDelegate?
    
    private var pickerView: UIPickerView = UIPickerView()
    private let filterDataSource: [FilterType] = [.all, .closed, .new]
    private let sortingDataSource: [SortType] = [.newToOld, .oldToNew]
    
    class func instanceFromNib() -> MyTicketsFilterHeader {
        let header = UINib(nibName: "MyTicketsFilterHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MyTicketsFilterHeader
        return header
    }
    
    func setUpTextFields() {
        pickerView.delegate = self
        pickerView.dataSource = self
        filterField.inputView = pickerView
        sortField.inputView = pickerView
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        toolbar.setItems([flexible, doneButton], animated: true)
        sortField.inputAccessoryView = toolbar
        filterField.inputAccessoryView = toolbar
        sortField.setIconForPicker(for: self.frame.width)
        filterField.setIconForPicker(for: self.frame.width)
    }
    
    private func selectView(_ selectedView: UIView) {
        UIView.animate(withDuration: 0.3) {
            selectedView.layer.borderWidth = 1
            selectedView.layer.borderColor = UIColor(hex: 0xCC0000).cgColor
            if selectedView == self.sortView {
                self.filterView.layer.borderWidth = 0
            } else {
                self.sortView.layer.borderWidth = 0
            }
        }
    }
    
    @objc private func dismissPicker() {
        endEditing(true)
    }

}

extension MyTicketsFilterHeader: SortFilterDelegate {
    func sortDidPressed() {
        selectView(sortView)
    }
    
    func filterDidPressed() {
        selectView(filterView)
    }
    
}

extension MyTicketsFilterHeader: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if sortField.isFirstResponder {
            return sortingDataSource.count
        }
        return filterDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if sortField.isFirstResponder {
            guard sortingDataSource.count > row else { return nil }
            return sortingDataSource[row].rawValue
        }
        guard filterDataSource.count > row else { return nil }
        return filterDataSource[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if sortField.isFirstResponder {
            guard sortingDataSource.count > row else { return }
            selectionDelegate?.sortingTypeDidSelect(sortingDataSource[row])
            return
        }
        guard filterDataSource.count > row else { return }
        selectionDelegate?.filterTypeDidSelect(filterDataSource[row])
    }
    
}

enum FilterType: String {
    case all = "All"
    case closed = "Closed"
    case new = "New"
}

enum SortType: String {
    case oldToNew = "Oldest to Newest"
    case newToOld = "Newest to Oldest"
}

protocol FilterSortingSelectionDelegate: AnyObject {
    func filterTypeDidSelect(_ selectedType: FilterType)
    func sortingTypeDidSelect(_ selectedType: SortType)
}
