//
//  ViewController.swift
//  Learn
//
//  Created by quan on 2017/9/9.
//  Copyright © 2017年 chq.Co.Ltd. All rights reserved.
//

import UIKit

enum AppIcon: String {
    case start = "start_icon"
    case end = "end_icon"
}


let isBeginKey = "isBeginKey"   //应用已经启动过
let beginDateKey = "beginDateKey"  //始于:XXXX年XX月XX日
let totalTimeKey = "totalTimeKey"  //累计时间
let beginTimeKey = "beginTimeKey"  //当天开始计时的时间
let isStartCountKey = "isStartCountKey"  //是否已经开始计时

class ViewController: UIViewController {
    
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var todayCountLabel: MZTimerLabel!
    @IBOutlet weak var countButton: UIButton!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var beginDayLabel: UILabel!
    @IBOutlet weak var tipsLabel: UILabel!
    
    
    let GRView = UIView()
    
    
    var isBegin: Bool {
        return UserDefaults.standard.bool(forKey: isBeginKey)
    }
    var totalTime = UserDefaults.standard.double(forKey: totalTimeKey) //秒
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCountLabel()
    }
    
    func initView() {
        setBeginDate(isReset: false)
        initCountButton()
        updateTotalLabel(time_second: totalTime)
        hightView(aView: countButton)
        
        todayCountLabel.updateLabelBlock = {
            [weak self] (timeInterval) in
//            print("更新了值\(timeInterval)")
            if timeInterval > 86399 {
                self?.todayCountLabel.pause()
                self?.tipsLabel.text = "连续学习一整天!? 忘记关了吧?"
                self?.tipsLabel.isHidden = false
            }
        }
    }
    
    func initCountButton() {
        countButton.layer.cornerRadius = countButton.frame.width * 0.5
        countButton.layer.masksToBounds = true
        
        
        //添加动画的按钮不响应点击事件
        countContainerView.addSubview(GRView)
        GRView.frame = countButton.frame
//        countButton.addTarget(self, action: #selector(countAction(_:)), for: .touchUpInside)
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(countAction(_:)))
        GRView.addGestureRecognizer(tapGR)
    }
    
    func updateCountLabel() {
        if isStartCount() {
            let beginTime = UserDefaults.standard.double(forKey: beginTimeKey)
            let interval = Date().timeIntervalSince1970 - beginTime
            todayCountLabel.start(atTime: interval)
            countButton.isSelected = true
        }
    }
    
    func updateAppIcon() {
        setAppIcon(name: isStartCount() ? AppIcon.end.rawValue : AppIcon.start.rawValue)
    }
    
    func updateTotalLabel(time_second: Double) {
        let countTime_hour = time_second / 3600
        let countTime_string = String(format: "%.2lf", locale: Locale.current, countTime_hour)
        let attText = NSMutableAttributedString(string: countTime_string + " 小时")
        let range = NSRange(location: attText.length - 2, length: 2)
        let fontAtt = [NSFontAttributeName: UIFont.systemFont(ofSize: 15)]
        attText.addAttributes(fontAtt, range: range)
        totalTimeLabel.attributedText = attText
    }
    
    
    func setBeginDate(isReset: Bool) {
        if !isBegin || isReset {
            let df = DateFormatter()
            df.dateFormat = "yyyy年MM月dd日"
            let beginDay = "始于: " + df.string(from: Date())
            beginDayLabel.text = beginDay
            UserDefaults.standard.set(beginDay, forKey: beginDateKey)
            UserDefaults.standard.set(true, forKey: isBeginKey)
        } else {
            beginDayLabel.text = UserDefaults.standard.string(forKey: beginDateKey)
        }
    }
    
    func countAction(_ button: UIButton) {
        if isStartCount() {
            endCount()
        } else {
            startCount()
        }
    }
    
    @IBAction func resetTotalTime(_ sender: UIButton) {
        let sureAction = UIAlertAction(title: "重置", style: .destructive) { (action) in
            self.resetAllTime()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        let controller = UIAlertController(title: "重置时间", message: "此操作将重置所有时间,包括当前学习时间与累计时间.请谨慎操作.", preferredStyle: .alert)
        
        controller.addAction(cancelAction)
        controller.addAction(sureAction)
        present(controller, animated: true, completion: nil)
    }
    
    
    func startCount() {
        countButton.isSelected = true
        todayCountLabel.start()
        UserDefaults.standard.set(true, forKey: isStartCountKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: beginTimeKey)
        setAppIcon(name: AppIcon.end.rawValue)
    }
    
    func endCount() {
        tipsLabel.isHidden = true
        countButton.isSelected = false
        GRView.isUserInteractionEnabled = false
        let endTime = Date()
        todayCountLabel.pause()
        let timeInternal = endTime.timeIntervalSince1970 - getStartTime()
        print("本次学习\(timeInternal)")
        totalTime = totalTime + timeInternal
        addTimeAnimation(aView: todayCountLabel)
        print("累计学习: \(totalTime)")
        
        UserDefaults.standard.set(false, forKey: isStartCountKey)
        UserDefaults.standard.set(totalTime, forKey: totalTimeKey)
        setAppIcon(name: AppIcon.start.rawValue)
        
    }
    
    func resetAllTime() {
        tipsLabel.isHidden = true
        UserDefaults.standard.set(false, forKey: isStartCountKey)
        todayCountLabel.reset()
        todayCountLabel.pause()
        countButton.isSelected = false
        updateTotalLabel(time_second: 0)
        UserDefaults.standard.set(0, forKey: totalTimeKey)
        setBeginDate(isReset: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isStartCount() -> Bool {
        return UserDefaults.standard.bool(forKey: isStartCountKey)
    }
    
    func getStartTime() -> TimeInterval {
        return UserDefaults.standard.double(forKey: beginTimeKey)
    }
    
    func addTimeAnimation(aView: UIView) {
        let a1 = CABasicAnimation()
        a1.keyPath = "transform.translation.y"
        a1.byValue = 200
        
        let a2 = CABasicAnimation()
        a2.keyPath = "transform.translation.x"
        a2.byValue = 30
        
        let a3 = CABasicAnimation()
        a3.keyPath = "transform.scale"
        a3.toValue = 0
        
        let groupAnima = CAAnimationGroup()
        groupAnima.animations = [a1, a2, a3]
        
        groupAnima.duration = 1.0
        groupAnima.delegate = self
        
        aView.layer.add(groupAnima, forKey: "group")
    }
    
    //呼吸背景animation
    func hightView(aView: UIView) {
        UIView.animate(withDuration: 1, animations: {
            aView.backgroundColor = aView.backgroundColor?.withAlphaComponent(0.1)
        }) { (finished) in
            self.darkView(aView: aView)
        }
    }
    
    func darkView(aView: UIView) {
        UIView.animate(withDuration: 1, animations: {
            aView.backgroundColor = aView.backgroundColor?.withAlphaComponent(0.4)
        }) { (finished) in
            self.hightView(aView: aView)
        }
    }
    
    func setAppIcon(name: String) {
        if #available(iOS 10.3, *) {
            guard UIApplication.shared.supportsAlternateIcons else {
                return
            }
            
            guard !name.isEmpty else {
                return
            }
            
            //这个方法在主动调用setAppIcon()时不会触发,已经被钩了.
            UIApplication.shared.setAlternateIconName(name, completionHandler: { (error) in
                if error != nil {
                    print("更换图标不成功. \(String(describing: error))")
                }
            })
        } else {
            print("不支持换应用icon")
        }
    }
    
}


extension ViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        GRView.isUserInteractionEnabled = true
        todayCountLabel.reset()
        todayCountLabel.pause()
        updateTotalLabel(time_second: totalTime)
    }
}





