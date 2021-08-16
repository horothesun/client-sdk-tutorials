import UIKit
import NexmoClient

class ViewController: UIViewController {
    
    let connectionStatusLabel = UILabel()
    private lazy var hangupButton: UIButton = {
        let button = UIButton()
        button.setTitle("Hangup", for: .normal)
        button.addTarget(self, action: #selector(hangup(_:)), for: .touchUpInside)
        return button
    }()
    let client = NXMClient.shared
    var call: NXMCall?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        NXMLogger.setLogLevel(.verbose)

        connectionStatusLabel.text = "Unknown"
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        hangupButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(connectionStatusLabel)
        view.addSubview(hangupButton)

        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[label]-20-|",
                options: [],
                metrics: nil,
                views: ["label" : connectionStatusLabel]
            )
        )
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[hangupButton]-20-|",
                options: [],
                metrics: nil,
                views: ["hangupButton" : hangupButton]
            )
        )
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-80-[label(20)]-[hangupButton]",
                options: [],
                metrics: nil,
                views: ["label" : connectionStatusLabel, "hangupButton" : hangupButton]
            )
        )
        
        client.setDelegate(self)
        client.login(withAuthToken: "ALICE_JWT")
    }

    @objc func hangup(_ action: UIAction) {
        print("🚫 \(#function)")

        guard let call = call else {
            print("🔴 No call!")
            return
        }

        call.hangup()
    }
    
    func displayIncomingCallAlert(call: NXMCall) {
        var from = "Unknown"
        if let otherParty = call.otherCallMembers.firstObject as? NXMCallMember {
            from = otherParty.channel?.from.data ?? "Unknown"
        }
        
        let alert = UIAlertController(title: "Incoming call from", message: from, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Answer", style: .default, handler: { _ in
            self.call = call
            call.answer(nil)
            
        }))
        alert.addAction(UIAlertAction(title: "Reject", style: .default, handler: { _ in
            call.reject(nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: NXMClientDelegate {
    
    func client(_ client: NXMClient, didChange status: NXMConnectionStatus, reason: NXMConnectionStatusReason) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .connected:
                self?.connectionStatusLabel.text = "Connected"
            case .disconnected:
                self?.connectionStatusLabel.text = "Disconnected"
            case .connecting:
                self?.connectionStatusLabel.text = "Connecting"
            @unknown default:
                self?.connectionStatusLabel.text = "Unknown"
            }
        }
    }
    
    func client(_ client: NXMClient, didReceiveError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionStatusLabel.text = error.localizedDescription
        }
    }
    
    func client(_ client: NXMClient, didReceive call: NXMCall) {
        call.setDelegate(self)
        DispatchQueue.main.async { [weak self] in
            self?.displayIncomingCallAlert(call: call)
        }
    }
}

extension ViewController: NXMCallDelegate {

    func call(_ call: NXMCall, didUpdate callMember: NXMCallMember, with status: NXMCallMemberStatus) {
        print("🔵 \(#function) - \(callMember.memberId) - status: \(status)")
    }

    func call(_ call: NXMCall, didUpdate callMember: NXMCallMember, isMuted muted: Bool) {
        print("🔵 \(#function) - \(callMember.memberId) - isMuted: \(muted)")
    }

    func call(_ call: NXMCall, didReceive error: Error) {
        print("🔴 \(#function) - \(error.localizedDescription)")
    }

}
