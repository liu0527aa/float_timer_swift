//
//  ViewController.swift
//  timer_swift
//
//  Created by lyh on 2025/12/29.
//  Revised for iOS 18: 6-Digit Integer Timestamp
//

import UIKit
import AVKit
import AVFoundation
import SnapKit
import Kronos

// MARK: - 1. 画中画内容控制器
class FloatClockViewController: AVPictureInPictureVideoCallViewController {
    
    // 只保留一个大大的 Label 显示6位数字
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .green // 亮绿色
        // 使用等宽字体，防止数字跳动时宽度变化
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .heavy)
        label.textAlignment = .center
        label.text = "000000"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 深色背景，对比度高
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        view.addSubview(timeLabel)
        
        // SnapKit 布局：居中撑满
        timeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
        }
        
        // 设置最佳显示比例 (长条形适合显示一串数字)
        self.preferredContentSize = CGSize(width: 160, height: 60)
    }
}

// MARK: - 2. 主控制器
class ViewController: UIViewController, AVPictureInPictureControllerDelegate {
    
    // 画中画控制器
    private var pipController: AVPictureInPictureController?
    
    // 内容 VC
    private lazy var clockPipVC: FloatClockViewController = {
        return FloatClockViewController()
    }()
    
    // 定时器
    // 替换 Timer
    private var displayLink: CADisplayLink?
    
    // UI
    private let startButton = UIButton(type: .system)
    private let syncLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupAudioSession() // 保活关键
        setupPiP()          // 画中画关键
        
        // 启动 NTP 同步
        startNTPSync()
    }
    
    // MARK: - NTP 同步
    private func startNTPSync() {
        syncLabel.text = "正在同步 NTP 时间..."
        // 使用字节跳动或阿里云的NTP服务，国内通常更快
        Clock.sync(from: "time1.bytedance.com", first: { date, offset in
            print("NTP 初次同步: \(date)")
        }, completion: { date, offset in
            print("NTP 精确同步完成: \(date)")
            DispatchQueue.main.async {
                self.syncLabel.text = "NTP 同步完成 (高精度)"
            }
        })
    }
    
    // MARK: - Setup AudioSession (防挂起)
    private func setupAudioSession() {
        do {
            // 必须 mixWithOthers，否则抖音一响你就停了
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession Error: \(error)")
        }
    }
    
    // MARK: - Setup PiP (VideoCall模式)
    private func setupPiP() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            // 使用 VideoCall 模式，不依赖视频播放，不黑屏
            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: self.view,
                contentViewController: clockPipVC
            )
            
            pipController = AVPictureInPictureController(contentSource: contentSource)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }
    
    // MARK: - 核心：时间计算逻辑
    @objc func tick() {
        // 1. 获取高精度时间 (优先 NTP，失败降级为系统时间)
        let now = Clock.now ?? Date()
        
        // 2. 转为毫秒级整数
        // timeIntervalSince1970 是秒 (如 1692864000.123)
        // 乘以 1000 变成毫秒 (如 1692864000123)
        let totalMilliseconds = Int64(now.timeIntervalSince1970 * 1000)
        
        // 3. 取最后 6 位
        // 使用取模运算 (%) 是获取后几位最高效的方法
        let last6Digits = totalMilliseconds % 1000000
        
        // 4. 格式化为字符串 (确保不足6位时前面补0，虽然概率很小)
        let text = String(format: "%06d", last6Digits)
        
        // 5. 更新 UI
        self.clockPipVC.timeLabel.text = text
    }
    // MARK: - 计时逻辑 (改为 CADisplayLink)
    private func startTimer() {
        stopTimer() // 防止重复开启
            
            // 创建 CADisplayLink，目标是 self，选择器是 tick
            displayLink = CADisplayLink(target: self, selector: #selector(tick))
            
            // 关键：加入到 .common 模式，防止滑动 ScrollView 时停止
            displayLink?.add(to: .main, forMode: .common)
    }
        
    private func stopTimer() {
            displayLink?.invalidate()
            displayLink = nil
    }
    // MARK: - UI & Actions
    private func setupUI() {
        startButton.setTitle("启动 6位毫秒时钟", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.frame = CGRect(x: 50, y: 300, width: 300, height: 60)
        startButton.addTarget(self, action: #selector(togglePiP), for: .touchUpInside)
        view.addSubview(startButton)
        
        syncLabel.frame = CGRect(x: 20, y: 380, width: 350, height: 30)
        syncLabel.textAlignment = .center
        syncLabel.font = .systemFont(ofSize: 14)
        syncLabel.textColor = .gray
        view.addSubview(syncLabel)
    }
    
    @objc private func togglePiP() {
        guard let pipController = pipController else { return }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            try? AVAudioSession.sharedInstance().setActive(true)
            pipController.startPictureInPicture()
        }
    }

    // MARK: - PiP Delegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        startTimer()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        stopTimer()
    }
}
