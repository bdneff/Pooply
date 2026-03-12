//
//  CameraView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 10/23/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

// MARK: - Main Camera View
struct CameraView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var isPresented: Bool
    @Binding var showManualEntry: Bool

    @State private var session = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var isCameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var hasRequestedPermission = AVCaptureDevice.authorizationStatus(for: .video) != .notDetermined

    // Photo picker
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Captured/selected image
    @State private var capturedImage: UIImage?
    @State private var showImagePreview = false
    @State private var isAnalyzing = false
    @State private var analysisResult: AnalysisResult?
    @State private var analysisError: String?

    // Retain the photo capture delegate
    @State private var photoCaptureDelegate: PhotoCaptureDelegate?

    var body: some View {
        ZStack {
            if let result = analysisResult, let image = capturedImage {
                // Results view
                AnalysisResultsView(
                    image: image,
                    result: result,
                    onSave: {
                        saveAnalysisResult(result)
                    },
                    onRetake: {
                        resetToCamera()
                    },
                    onClose: {
                        isPresented = false
                    }
                )
            } else if isAnalyzing, let image = capturedImage {
                // Analyzing view
                AnalyzingView(
                    image: image,
                    errorMessage: analysisError,
                    onCancel: {
                        resetToCamera()
                    },
                    onRetry: {
                        analysisError = nil
                        analyzeImage(image)
                    }
                )
            } else if showImagePreview, let image = capturedImage {
                // Image preview/analysis view
                ImagePreviewView(
                    image: image,
                    isAnalyzing: $isAnalyzing,
                    onRetake: {
                        capturedImage = nil
                        showImagePreview = false
                    },
                    onConfirm: {
                        analyzeImage(image)
                    },
                    onClose: {
                        isPresented = false
                    }
                )
            } else if isCameraAuthorized || !hasRequestedPermission {
                // Show camera preview (or black screen while permission is being requested)
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .onAppear {
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        if status == .notDetermined {
                            requestCameraAccess()
                        } else if status == .authorized {
                            startCamera()
                        }
                    }
                    .onDisappear {
                        session.stopRunning()
                    }

                // Overlay (only show controls when authorized)
                if isCameraAuthorized {
                    VStack {
                        // Top bar with close button + free analyses badge
                        HStack {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                session.stopRunning()
                                isPresented = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(glassBackground)
                                    .clipShape(Circle())
                            }
                            Spacer()

                            // Free analyses remaining badge
                            if !SubscriptionService.shared.isSubscribed {
                                let remaining = SubscriptionService.shared.freeAnalysesRemaining
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("\(remaining) free")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(glassBackground)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        Spacer()

                        // Instruction text
                        Text("Position in frame")
                            .font(Theme.Fonts.body())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(glassBackground)
                            .clipShape(Capsule())

                        Spacer().frame(height: 20)

                        // Framing box
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                            .frame(width: 260, height: 260)

                        Spacer()

                        // Bottom toolbar
                        HStack(spacing: 40) {
                            // Library button - liquid glass
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Library")
                                        .font(Theme.Fonts.caption())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(glassBackground)
                                .clipShape(Capsule())
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                handleSelectedPhoto(newItem)
                            }

                            // Capture button - white circle only
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                capturePhoto()
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 80, height: 80)

                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 64, height: 64)
                                }
                            }

                            // Manual button - liquid glass
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                session.stopRunning()
                                isPresented = false
                                showManualEntry = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Manual")
                                        .font(Theme.Fonts.caption())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(glassBackground)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            } else {
                // Camera denied/restricted — show settings prompt
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.textTertiary)

                    Text("Camera Access Required")
                        .font(Theme.Fonts.heading())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Please enable camera access in Settings to use this feature.")
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Still allow library access
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text("Choose from Library")
                            .font(Theme.Fonts.bodyBold())
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        handleSelectedPhoto(newItem)
                    }

                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Settings")
                            .font(Theme.Fonts.bodyBold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .background((isCameraAuthorized || !hasRequestedPermission) ? Color.black : Theme.Colors.background)
    }

    // Liquid glass background
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular)
        } else {
            ZStack {
                Color.white.opacity(0.15)
                Color.black.opacity(0.3)
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Photo Handling

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    capturedImage = image
                    showImagePreview = true
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate { [self] image in
            DispatchQueue.main.async {
                self.capturedImage = image
                self.showImagePreview = true
                self.photoCaptureDelegate = nil // Release after capture
            }
        }
        photoCaptureDelegate = delegate // Retain the delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        analysisError = nil
        showImagePreview = false

        // Track free analysis usage
        SubscriptionService.shared.useAnalysis()

        Task {
            do {
                let result = try await AnalysisService.shared.analyzeImage(image)

                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    // Keep isAnalyzing true to show error state
                }
            }
        }
    }

    private func saveAnalysisResult(_ result: AnalysisResult) {
        var log = result.toLog()
        log.isManualEntry = false
        userViewModel.addLog(log)

        // Upload image and save to Firebase with imageURL
        Task {
            do {
                if let image = capturedImage {
                    let url = try await FirebaseService.shared.uploadImage(image, for: log.id)
                    log.imageURL = url
                }
                try await FirebaseService.shared.saveLog(log)
                // Update local log with imageURL
                await MainActor.run {
                    userViewModel.updateLog(log)
                }
            } catch {
                // Still try to save log without imageURL
                try? await FirebaseService.shared.saveLog(log)
            }
        }

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        isPresented = false
    }

    private func resetToCamera() {
        capturedImage = nil
        showImagePreview = false
        isAnalyzing = false
        analysisResult = nil
        analysisError = nil
    }

    // MARK: - Camera Setup

    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.hasRequestedPermission = true
                self.isCameraAuthorized = granted
                if granted {
                    startCamera()
                }
            }
        }
    }

    func startCamera() {
        guard !session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            session.beginConfiguration()

            // Remove existing inputs/outputs
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()
            session.startRunning()
        }
    }
}

// MARK: - Photo Capture Delegate

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}

// MARK: - Image Preview View

struct ImagePreviewView: View {
    let image: UIImage
    @Binding var isAnalyzing: Bool
    let onRetake: () -> Void
    let onConfirm: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                Spacer()

                // Bottom buttons
                if isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)

                        Text("Analyzing...")
                            .font(Theme.Fonts.body())
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 60)
                } else {
                    HStack(spacing: 20) {
                        // Retake button
                        Button(action: onRetake) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Retake")
                                    .font(Theme.Fonts.bodyBold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Analyze button
                        Button(action: onConfirm) {
                            HStack(spacing: 8) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Analyze")
                                    .font(Theme.Fonts.bodyBold())
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - Analyzing View

struct AnalyzingView: View {
    let image: UIImage
    let errorMessage: String?
    let onCancel: () -> Void
    let onRetry: () -> Void

    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var dots = ""

    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Beautiful gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.Colors.tealTint,
                        Theme.Colors.background,
                        Theme.Colors.blueTint.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle animated gradient orbs
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -200)

                Circle()
                    .fill(Theme.Colors.tealTint.opacity(0.2))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 120, y: 300)
            }
            .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Animated mascot with rings
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.4), Theme.Colors.tealTint.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)

                    // Middle ring
                    Circle()
                        .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotationAngle))

                    // Inner circle with mascot
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.15), Theme.Colors.tealTint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    MascotCircle(size: 72)
                }

                // Status text
                VStack(spacing: Theme.Spacing.sm) {
                    if let error = errorMessage {
                        Text("Analysis Failed")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.blood)

                        Text(error)
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                    } else {
                        Text("Analyzing\(dots)")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .onReceive(timer) { _ in
                                if dots.count >= 3 {
                                    dots = ""
                                } else {
                                    dots += "."
                                }
                            }

                        Text("Our AI is examining your sample")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Buttons
                if errorMessage != nil {
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: onRetry) {
                            Text("Try Again")
                                .font(Theme.Fonts.bodyBold())
                                .foregroundStyle(Theme.Colors.textOnPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.Colors.primary)
                                .clipShape(Capsule())
                        }

                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(Theme.Fonts.body())
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.xxl)
                } else {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Analysis Results View

struct AnalysisResultsView: View {
    let image: UIImage
    let result: AnalysisResult
    let onSave: () -> Void
    let onRetake: () -> Void
    let onClose: () -> Void

    @State private var showContent = false
    @State private var scoreAnimated: Int = 0

    // Use unified scoring from UserViewModel (factors in type, color, size, blood)
    private var percentileScore: Int {
        let log = result.toLog()
        return UserViewModel.calculatePoopScoreStatic(for: log)
    }

    // Color based on score ranges (stricter thresholds)
    private var scoreColor: Color {
        if percentileScore >= 85 {
            return Theme.Colors.good // Green - only for truly good scores
        } else if percentileScore >= 70 {
            return Color(hex: "#F5A623") // Amber - decent but room for improvement
        } else if percentileScore >= 50 {
            return Theme.Colors.hard // Orange - needs work
        } else {
            return Color(hex: "#9C27B0") // Purple - poor scores
        }
    }

    // Dynamic gradient for background - more visually interesting
    private var backgroundGradient: LinearGradient {
        let baseColor = scoreColor
        return LinearGradient(
            colors: [
                baseColor.opacity(0.95),
                baseColor,
                baseColor.opacity(0.8),
                baseColor.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Secondary accent color for visual interest
    private var accentGradient: some View {
        ZStack {
            // Main gradient
            backgroundGradient

            // Subtle radial highlight at top
            RadialGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )

            // Subtle dark gradient at bottom for depth
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var scoreLabel: String {
        if percentileScore >= 85 {
            return "Excellent"
        } else if percentileScore >= 75 {
            return "Good"
        } else if percentileScore >= 60 {
            return "Fair"
        } else if percentileScore >= 45 {
            return "Needs Work"
        } else {
            return "Poor"
        }
    }

    var body: some View {
        ZStack {
            // Full-screen dynamic gradient background
            accentGradient
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.md)

                Spacer()

                // Main score section
                VStack(spacing: Theme.Spacing.lg) {
                    // Title
                    Text("POOP SCORE")
                        .font(Theme.Fonts.label(14))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(showContent ? 1 : 0)

                    // Large score in white circle
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 200, height: 200)

                        // Main white circle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 170, height: 170)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)

                        // Score number
                        VStack(spacing: 4) {
                            Text("\(scoreAnimated)")
                                .font(Theme.Fonts.hero(72))
                                .foregroundColor(scoreColor)
                                .contentTransition(.numericText())

                            Text("out of 100")
                                .font(Theme.Fonts.caption(13))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)

                    // Score label badge
                    Text(scoreLabel)
                        .font(Theme.Fonts.bodyBold())
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                        .opacity(showContent ? 1 : 0)
                }

                Spacer()

                // Bottom section with analysis and metrics
                VStack(spacing: Theme.Spacing.md) {
                    // AI Analysis card
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(scoreColor)

                            Text("AI Analysis")
                                .font(Theme.Fonts.captionBold())
                                .foregroundColor(Theme.Colors.textPrimary)
                        }

                        Text(result.analysis)
                            .font(Theme.Fonts.body(15))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    // Metrics row
                    HStack(spacing: Theme.Spacing.sm) {
                        ScoreMetricPill(
                            icon: "drop.fill",
                            value: "\(Int((result.hydrationPercentage ?? 0.5) * 100))%",
                            label: "Hydration",
                            color: Theme.Colors.hydration
                        )

                        ScoreMetricPill(
                            icon: "leaf.fill",
                            value: "\(Int((result.fiberPercentage ?? 0.5) * 100))%",
                            label: "Fiber",
                            color: Theme.Colors.fiber
                        )

                        if result.bloodPercentage > 0 {
                            ScoreMetricPill(
                                icon: "drop.triangle.fill",
                                value: "\(Int(result.bloodPercentage * 100))%",
                                label: "Blood",
                                color: Theme.Colors.blood
                            )
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    // Action buttons
                    HStack(spacing: Theme.Spacing.md) {
                        Button(action: onRetake) {
                            Text("Retake")
                                .font(Theme.Fonts.bodyBold())
                                .foregroundColor(scoreColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onSave()
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Save Log")
                                    .font(Theme.Fonts.bodyBold())
                            }
                            .foregroundColor(scoreColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            // Animate the score counting up
            animateScore()
        }
    }

    private func animateScore() {
        let target = percentileScore
        let duration: Double = 1.0
        let steps = 30
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                withAnimation(.easeOut(duration: 0.05)) {
                    scoreAnimated = Int(Double(target) * Double(step) / Double(steps))
                }
            }
        }
    }

}

// MARK: - Score Metric Pill

struct ScoreMetricPill: View {
    let icon: String
    let value: String
    var label: String? = nil
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(Theme.Fonts.captionBold(12))
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            if let label = label {
                Text(label)
                    .font(Theme.Fonts.micro())
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm + 4)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}


#Preview {
    CameraView(isPresented: .constant(true), showManualEntry: .constant(false))
}

