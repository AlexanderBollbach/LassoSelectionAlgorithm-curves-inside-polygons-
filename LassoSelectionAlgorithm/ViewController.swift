//
//  ViewController.swift
//  LassoSelectionAlgorithm
//
//  Created by Alexander Bollbach on 11/30/17.
//  Copyright © 2017 Alexander Bollbach. All rights reserved.
//

import UIKit


class Layer {
    var selected = false
    var points = [CGPoint]()
}

class RenderingView: UIView {
    
    let lassoButton = UIButton()
    let clearButton = UIButton()
    let undoLastLineButton = UIButton()
    var lassoMode = false
    var lasso = Layer()
    var layers = [Layer]()
    var currentLayer: Layer?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .red
        let displaylink = CADisplayLink(target: self, selector: #selector(step))
        displaylink.add(to: .current, forMode: .defaultRunLoopMode)
        lassoButton.setTitle("lasso", for: .normal)
        clearButton.setTitle("clear", for: .normal)
        undoLastLineButton.setTitle("undo Last Line", for: .normal)
        addSubview(lassoButton)
        addSubview(undoLastLineButton)
        addSubview(clearButton)
        lassoButton.translatesAutoresizingMaskIntoConstraints = false
        lassoButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        lassoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        lassoButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        lassoButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        lassoButton.addTarget(self, action: #selector(lassoButtonTapped), for: .touchUpInside)
        
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        clearButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        clearButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        clearButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        
        
        undoLastLineButton.translatesAutoresizingMaskIntoConstraints = false
        undoLastLineButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        undoLastLineButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        undoLastLineButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 100).isActive = true
        undoLastLineButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        undoLastLineButton.addTarget(self, action: #selector(undoLastLineButtonTapped), for: .touchUpInside)
    }
    
    @objc func step() {
        setNeedsDisplay()
    }
    @objc func lassoButtonTapped() {
        lassoMode = !lassoMode
        lassoButton.setTitle(lassoMode ? "[lasso]" : "lasso", for: .normal)
    }
    @objc func clearButtonTapped() {
        layers = []
    }
    @objc func undoLastLineButtonTapped() {
        _ = layers.popLast()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if lassoMode {
            lasso.points = []
            return
        }
        currentLayer = Layer()
        layers.append(currentLayer!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if lassoMode {
            lasso.points.append(point)
            return
        }
        currentLayer?.points.append(point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let firstPoint = lasso.points.first {
            lasso.points.append(firstPoint)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext()else { return }
        
        context.clear(rect)
        
        
        layers.forEach { layer in
            
            context.setStrokeColor(layer.selected ? UIColor.white.cgColor : UIColor.blue.cgColor)
            
            for point in layer.points {
                if point == layer.points.first! {
                    context.move(to: point)
                } else {
                    context.addLine(to: point)
                }
            }
            context.strokePath()
        }
        
        context.setStrokeColor(UIColor.orange.cgColor)
        
        
        
        // render lasso
        
        if lasso.points.count > 0 {
            
            for i in 0...lasso.points.count - 1 {
                
                let p = lasso.points[i]
                
                if i == 0 {
                    context.move(to: p)
                } else {
                    context.addLine(to: p)
                }
                
            }
        }
        
        
        
        context.strokePath()
        
        
        
        
        
        
        
        // run select ALGO
        lassoSelect()
    }
    
    
    
    
    
    
    
    
    
    
    
    // LASSO ALGO
    func lassoSelect() {
        
        
        
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX: CGFloat = 0
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY: CGFloat = 0
        
        lasso.points.forEach { point in // find min x
            if point.x < minX { minX = point.x }
        }
        lasso.points.forEach { point in // find max x
            if point.x > maxX { maxX = point.x }
        }
        lasso.points.forEach { point in // find min y
            if point.y < minY { minY = point.y }
        }
        lasso.points.forEach { point in // find max y
            if point.y > maxY { maxY = point.y }
        }
        
        // bounding box check
        for layer in layers {
            var pointInside = false
            for point in layer.points {
                if point.x > minX && point.x < maxX && point.y > minY && point.y < maxY {
                    pointInside = true
                }
            }
            layer.selected = pointInside
        }
        
        // create sides
        struct Side {
            let begin: CGPoint
            let end: CGPoint
        }
        
        // side length for optimization
        
        var sides = [Side]()
        
        guard lasso.points.count > 2 else { return }
        
        var sideBegin = lasso.points[0]
        
        for i in 0...lasso.points.count - 1 - 1 {
            
            let currentPoint = lasso.points[i]
            
            let enoughDistance = abs(currentPoint.x - sideBegin.x) > 5 && abs(currentPoint.y - sideBegin.y) > 5
            
            if (currentPoint.x != sideBegin.x && currentPoint.y != sideBegin.y && enoughDistance) {
            
                sides.append(Side(begin: sideBegin, end: lasso.points[i + 1]))
                
                sideBegin = lasso.points[i + 1]
            }
 
 
            
            
        }
        
        
        
        
        // ray intersection helper function
        
        let pointRayIntersectsSides: (CGPoint, [Side]) -> Bool = { (point, sides) in
            
            guard sides.count > 1 else { return false }
            
            let layers = self.layers
            let lasso = self.lasso
            
            var numIntersections = 0
            
            // [check intersection sides]
            for i in 0...sides.count - 1 {
                
                let side = sides[i]
                
                let t = point
                let v2 = side.begin.y < side.end.y ? side.begin : side.end
                let v1 = v2 == side.begin ? side.end : side.begin
                
                let testPointBetweenVertices = t.y > v2.y && t.y < v1.y
                if  testPointBetweenVertices {
                    let xIntersection = v1.x + ((t.y - v1.y) / (v2.y - v1.y)) * (v2.x - v1.x)
                    if xIntersection > t.x {
                        numIntersections += 1
                    }
                }
            }
            
            let intersectionCountOdd = !(numIntersections % 2 == 0)
            
            if intersectionCountOdd {
                return true
            }
            
            return false
        }
        
        
        
        
        layers.forEach {
            $0.selected = false
        }
        
        // ray checks
        
        for layer in layers {
            
            for point in layer.points {
                // check ray on each point
                if pointRayIntersectsSides(point, sides) {
                    layer.selected = true
                }
            }
        }
        
        
        
    }
    
    
    
}






// boilerplate

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let renderingView = RenderingView()
        renderingView.pinTo(superView: view)
        
    }
}

extension UIView {
    func pinTo(superView: UIView) {
        superView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        self.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
    }
}
