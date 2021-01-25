//
//  StatsBarChart.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class StatsBarChart: UIView {

    struct Data {
        let legend: String
        let number: Int
    }

    struct Constants {
        static let unitHeight: CGFloat = 4.0
        static let unitWidth: CGFloat = 40.0
        static let barColor = UIColor(hex: 0xCC0000)
        static let horizontalLineColor = UIColor(hex: 0xF2F2F7)
    }

    var dataList: [Data] = [] {
        didSet {
            setNeedsLayout()
        }
    }

    let stackView: UIStackView

    override init(frame: CGRect) {
        stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .bottom
        stackView.axis = .horizontal

        super.init(frame: frame)

        addHorizontalLines(linesCount: 4)
        addSubview(stackView)
        stackView.pinEdges(to: self, leadingOffset: 2, trailingOffset: 2)
    }

    required init?(coder: NSCoder) {
        stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .bottom
        stackView.axis = .horizontal
        
        super.init(coder: coder)
        
        addHorizontalLines(linesCount: 4)
        addSubview(stackView)
        stackView.pinEdges(to: self, leadingOffset: 2, trailingOffset: 2)
    }
    
    private func addHorizontalLines(linesCount: Int, lineHeight: CGFloat = 1) {
        guard linesCount > 1 else { return }
        let containerHeight = frame.height
        let containerWidth = frame.width
        let barMaxHeight = max(0, containerHeight - StatsBarView.Constants.legendFont.lineHeight - StatsBarView.Constants.itemSpacing)
        let linesSpacing = (barMaxHeight - CGFloat(linesCount) * lineHeight) / (CGFloat(linesCount) - 1)
        for i in 0..<linesCount {
            let lineView = UIView(frame: CGRect(x: 0, y: (linesSpacing + lineHeight) * CGFloat(i), width: containerWidth, height: lineHeight))
            lineView.backgroundColor = Constants.horizontalLineColor
            addSubview(lineView)
        }
    }
    
    func factoryViewList(containerHeight: CGFloat) -> [UIView] {

        let maxNumber = dataList.reduce(0) {
            return max($1.number, $0)
        }

        let shouldUseRelativeHeight = CGFloat(maxNumber) * Constants.unitHeight > (containerHeight / 2.0)

        var views = [UIView]()
        
        for data in dataList {
            let bar = StatsBarView()
            bar.legendLabel.text = data.legend
            bar.widthAnchor.constraint(equalToConstant: Constants.unitWidth).isActive = true

            bar.containerHeight = containerHeight

            if shouldUseRelativeHeight {
                bar.barHeightPercentage = CGFloat(data.number) / CGFloat(maxNumber)
            } else {
                bar.barHeightConstant = CGFloat(data.number) * Constants.unitHeight
            }

            bar.bar.backgroundColor = Constants.barColor
            views.append(bar)
        }

        return views
    }
    
    func setDataList(with: [ChartData]) {
        let chartData = with.map { Data(legend: $0.legendTitle ?? "", number: $0.value ?? 0) }
        dataList = chartData
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        for view in factoryViewList(containerHeight: frame.height) {
            stackView.addArrangedSubview(view)
        }
    }
}
