import AVFoundation
import AWSPluginsCore
import FaceLiveness
import SwiftUI
import UIKit
import VerifyIQeKYC

/// Native AWS Face Liveness (Amplify UI) behind the SDK's liveness seam. iOS 15+.
///
/// The video streams from the device straight to AWS, signed with short-lived credentials the
/// VerifyIQ backend vends for this one attempt. No Amplify configuration or Cognito pool is needed.
/// The runner never decides the verdict: the backend reads it from AWS.
///
/// ```swift
/// if #available(iOS 15.0, *) { configuration.livenessRunner = EKYCAmplifyLivenessRunner() }
/// ```
public final class EKYCAmplifyLivenessRunner: EKYCPresentingLivenessRunner {
    public weak var presentingViewController: UIViewController?
    private var host: UIViewController?

    public init() {}

    public var supportsCurrentDevice: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    public func runLiveness(_ start: EKYCLivenessStart, completion: @escaping (EKYCLivenessRunResult) -> Void) {
        DispatchQueue.main.async { [self] in
            guard let presenter = presentingViewController, let credentials = start.credentials,
                  let region = start.region, !region.isEmpty else {
                return completion(.failed(.livenessUnavailable))
            }
            let state = LivenessPresentation()
            let screen = LivenessScreen(sessionID: start.livenessSessionId, region: region,
                                        provider: EKYCStaticCredentialsProvider(credentials: credentials),
                                        presentation: state) { [weak self] result in
                DispatchQueue.main.async { self?.finish(Self.map(result), completion: completion) }
            }
            let host = UIHostingController(rootView: screen)
            host.modalPresentationStyle = .fullScreen
            host.isModalInPresentation = true
            self.host = host
            presenter.present(host, animated: true)
        }
    }

    private func finish(_ result: EKYCLivenessRunResult, completion: @escaping (EKYCLivenessRunResult) -> Void) {
        guard let host = host else { return }
        self.host = nil
        host.dismiss(animated: true) { completion(result) }
    }

    /// A timeout, a face that was not positioned and a session that ended on its own count as a
    /// finished attempt: the outcome of the check is read on the server, never on the device.
    static func map(_ result: Result<Void, FaceLivenessDetectionError>) -> EKYCLivenessRunResult {
        switch result {
        case .success:
            return .completed
        case .failure(let error):
            switch error {
            case .userCancelled:
                return .cancelled
            case .cameraPermissionDenied:
                return .failed(.cameraPermissionDenied)
            case .cameraNotAvailable:
                return .failed(.unsupportedDevice)
            case .accessDenied, .invalidRegion, .invalidSignature, .serviceQuotaExceeded:
                return .failed(.livenessUnavailable)
            case .internalServer, .serviceUnavailable, .throttling:
                return .failed(.serviceUnavailable)
            default:
                return .completed
            }
        }
    }
}

/// Hands the short-lived credentials of this one attempt to Amplify.
struct EKYCStaticCredentialsProvider: AWSCredentialsProvider {
    let credentials: EKYCLivenessCredentials

    func fetchAWSCredentials() async throws -> AWSCredentials {
        EKYCTemporaryCredentials(accessKeyId: credentials.accessKeyId, secretAccessKey: credentials.secretAccessKey,
                                 sessionToken: credentials.sessionToken,
                                 expiration: credentials.expiration ?? Date().addingTimeInterval(15 * 60))
    }
}

struct EKYCTemporaryCredentials: AWSTemporaryCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}

final class LivenessPresentation: ObservableObject {
    @Published var isPresented = true
}

struct LivenessScreen: View {
    let sessionID: String
    let region: String
    let provider: AWSCredentialsProvider
    @ObservedObject var presentation: LivenessPresentation
    let onCompletion: (Result<Void, FaceLivenessDetectionError>) -> Void

    var body: some View {
        FaceLivenessDetectorView(sessionID: sessionID, credentialsProvider: provider, region: region,
                                 disableStartView: false, isPresented: $presentation.isPresented,
                                 onCompletion: onCompletion)
    }
}
