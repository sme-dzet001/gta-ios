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
    
    private var sortingPickerView: UIPickerView = UIPickerView()
    private var filterPickerView: UIPickerView = UIPickerView()
    private let filterDataSource: [FilterType] = [.all, .new, .closed]
    private let sortingDataSource: [SortType] = [.newToOld, .oldToNew]
    
    class func instanceFromNib() -> MyTicketsFilterHeader {
        let header = UINib(nibName: "MyTicketsFilterHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MyTicketsFilterHeader
        return header
    }
    
    func setUpTextFields() {
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(dismissPicker))
        cancelTap.cancelsTouchesInView = false
        addGestureRecognizer(cancelTap)
        sortingPickerView.delegate = self
        sortingPickerView.dataSource = self
        filterPickerView.delegate = self
        filterPickerView.dataSource = self
        filterField.inputView = filterPickerView
        sortField.inputView = sortingPickerView
        filterField.selectionDelegate = self
        sortField.selectionDelegate = self
        filterField.setUpTouch()
        sortField.setUpTouch()
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonDidPressed))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexible, doneButton], animated: true)
        sortField.inputAccessoryView = toolbar
        filterField.inputAccessoryView = toolbar
    }
    
    func setUpObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(dismissPicker), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissPicker), name: UIApplication.didBecomeActiveNotification, object: nil)
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
        } completion: { _ in
            if selectedView == self.sortView {
                let row = self.sortingDataSource.firstIndex(of: Preferences.ticketsSortingType) ?? 0
                self.sortingPickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                let row = self.filterDataSource.firstIndex(of: Preferences.ticketsFilterType) ?? 0
                self.filterPickerView.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    @objc private func doneButtonDidPressed() {
        if sortField.isFirstResponder {
            let selectedSortingIndex = sortingPickerView.selectedRow(inComponent: 0)
            let sortingType = sortingDataSource[selectedSortingIndex]
            selectionDelegate?.sortingTypeDidSelect(sortingType)
        } else {
            let selectedFilterIndex = filterPickerView.selectedRow(inComponent: 0)
            let filterType = filterDataSource[selectedFilterIndex]
            selectionDelegate?.filterTypeDidSelect(filterType)
        }
        endEditing(true)
    }
    
    @objc private func dismissPicker() {
        self.filterView.layer.borderWidth = 0
        self.sortView.layer.borderWidth = 0
        endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

}

extension MyTicketsFilterHeader: SelectionDelegateDelegate {
    func textFieldWillSelect(_ textField: UITextField) {
        dismissPicker()
        if textField == sortField {
            selectView(sortView)
        } else {
            selectView(filterView)
        }
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
//        if sortField.isFirstResponder {
//            guard sortingDataSource.count > row else { return }
//            selectionDelegate?.sortingTypeDidSelect(sortingDataSource[row])
//            return
//        }
//        guard filterDataSource.count > row else { return }
//        selectionDelegate?.filterTypeDidSelect(filterDataSource[row])
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
