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

    // Dedicated serial queue for all session configuration and start/stop calls.
    // Without this, .onDisappear can fire stopRunning on main while startCamera is
    // still inside beginConfiguration/commitConfiguration on a background queue,
    // which throws NSGenericException.
    private let sessionQueue = DispatchQueue(label: "com.pooply.camera.session")

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
                        stopCamera()
                    }

                // Overlay (only show controls when authorized)
                if isCameraAuthorized {
                    VStack {
                        // Top bar with close button + free analyses badge
                        HStack {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                stopCamera()
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

                            // Free analyses badge removed — app is free.
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
                                        .font(.system(size: 16, weight: .bold))
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
                                stopCamera()
                                isPresented = false
                                showManualEntry = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 16, weight: .bold))
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
        sessionQueue.async {
            guard !session.isRunning else { return }

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

    func stopCamera() {
        // Serialized with startCamera so we never stop mid-configuration.
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
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
                                    .font(.system(size: 16, weight: .bold))
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
                                    .font(.system(size: 16, weight: .bold))
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

    @State private var sweepRotation: Double = 0
    @State private var glowPulse: Bool = false
    @State private var dotCount: Int = 0

    private let ringOuterDiameter: CGFloat = 300
    private let ringThickness: CGFloat = 24

    private let dotTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    private var dotsString: String {
        String(repeating: ".", count: dotCount)
    }

    var body: some View {
        ZStack {
            MeshBackground()
                .ignoresSafeArea()

            // Top chrome: thumbnail (left) + close (right)
            VStack {
                HStack(alignment: .center) {
                    // Captured photo thumbnail
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.85), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Spacer()

                    CloseButton(action: onCancel)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.md)

                Spacer()
            }

            // Center stage
            if errorMessage == nil {
                analyzingStage
            } else {
                errorStage
            }
        }
        .onAppear {
            // Indeterminate barber-pole sweep
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                sweepRotation = 360
            }
            // Soft outer glow pulse
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }

    // MARK: - Analyzing center stage

    private var analyzingStage: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            ZStack {
                // Soft outer glow that breathes
                Circle()
                    .fill(Theme.Colors.iconBlue400.opacity(glowPulse ? 0.32 : 0.16))
                    .frame(width: ringOuterDiameter + 60, height: ringOuterDiameter + 60)
                    .blur(radius: 28)

                // Empty track
                Circle()
                    .stroke(
                        Color.white.opacity(0.55),
                        style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                    )
                    .frame(width: ringOuterDiameter, height: ringOuterDiameter)

                // Indeterminate sweeping arc — 30% of the circumference, spinning.
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.Colors.iconBlue300,
                                Theme.Colors.iconBlue400,
                                Theme.Colors.iconBlue500,
                                Theme.Colors.iconBlue400
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                    )
                    .frame(width: ringOuterDiameter, height: ringOuterDiameter)
                    .rotationEffect(.degrees(sweepRotation - 90))

                // Inside ring: label + animated dots
                VStack(spacing: 6) {
                    Text("Analyzing")
                        .font(Theme.Fonts.heading(22))
                        .foregroundStyle(Theme.Colors.neutral900)
                    Text(dotsString)
                        .font(.custom("PlusJakartaSans-ExtraBold", size: 28))
                        .foregroundStyle(Theme.Colors.iconBlue500)
                        .frame(height: 32)
                        .frame(minWidth: 60)
                }
            }
            .shadow(color: Theme.Colors.iconBlue500.opacity(0.22), radius: 24, x: 0, y: 10)

            Spacer()

            Text("Our AI is examining your sample")
                .font(Theme.Fonts.body(15))
                .foregroundStyle(Theme.Colors.neutral900.opacity(0.6))
                .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Error stage

    private var errorStage: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Theme.Colors.hard)

                Text("Analysis Failed")
                    .font(Theme.Fonts.heading())
                    .foregroundStyle(Theme.Colors.neutral900)

                Text(errorMessage ?? "Something went wrong.")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.neutral900.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.cardPadding)
            .frame(maxWidth: .infinity)
            .glassSurface(radius: Theme.Radius.large)
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.neutral900)
                        .clipShape(Capsule())
                        .cardShadow()
                }
                .buttonStyle(BouncyButtonStyle())

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Theme.Colors.neutral900)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .glassSurface(radius: Theme.Radius.pill)
                }
                .buttonStyle(BouncyButtonStyle())
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.bottom, Theme.Spacing.xxl)
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

    @State private var gaugeFill: CGFloat = 0
    @State private var scoreAnimated: Int = 0
    @State private var ringPulse: Bool = false
    @State private var showSupporting: Bool = false
    @State private var confettiStart: Date? = nil

    private let ringOuterDiameter: CGFloat = 300
    private let ringThickness: CGFloat = 24

    private var percentileScore: Int {
        let log = result.toLog()
        return UserViewModel.calculatePoopScoreStatic(for: log)
    }

    private var scoreColor: Color {
        switch percentileScore {
        case 85...100: return Theme.Colors.good
        case 70..<85:  return Theme.Colors.amber
        case 50..<70:  return Theme.Colors.hard
        default:       return Theme.Colors.lavender
        }
    }

    private var darkScoreColor: Color {
        switch percentileScore {
        case 85...100: return Color(hex: "#14532D")
        case 70..<85:  return Color(hex: "#78350F")
        case 50..<70:  return Color(hex: "#7F1D1D")
        default:       return Color(hex: "#3B0764")
        }
    }

    private var scoreLabel: String {
        switch percentileScore {
        case 85...100: return "Excellent"
        case 75..<85:  return "Good"
        case 60..<75:  return "Fair"
        case 45..<60:  return "Needs Work"
        default:       return "Poor"
        }
    }

    var body: some View {
        ZStack {
            MeshBackground()
                .ignoresSafeArea()

            // Confetti burst layer — full-screen, behind content but above bg
            ConfettiBurstView(startDate: confettiStart)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        CloseButton(action: onClose)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.md)

                    // MARK: - Hero: Gauge ring with giant score inside
                    gaugeHero
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)

                    // MARK: - Score Label
                    VStack(spacing: 8) {
                        Text("POOP SCORE")
                            .font(Theme.Fonts.label(11))
                            .foregroundStyle(darkScoreColor.opacity(0.55))
                            .tracking(1.5)

                        Text(scoreLabel)
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(darkScoreColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(scoreColor.opacity(0.25))
                            .clipShape(Capsule())
                    }
                    .opacity(showSupporting ? 1 : 0)
                    .padding(.bottom, Theme.Spacing.xl)

                    // MARK: - AI Analysis Card (glass)
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(scoreColor)
                            Text("AI Analysis")
                                .font(Theme.Fonts.captionBold())
                                .foregroundStyle(Theme.Colors.textOnGlass)
                        }

                        Text(result.analysis)
                            .font(Theme.Fonts.body(15))
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.78))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.cardPadding)
                    .glassSurface(radius: 20)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .opacity(showSupporting ? 1 : 0)
                    .offset(y: showSupporting ? 0 : 30)

                    // MARK: - Metric Pills (glass)
                    HStack(spacing: Theme.Spacing.sm) {
                        ScoreMetricPill(
                            icon: "drop.fill",
                            value: "\(Int((result.hydrationPercentage ?? 0.5) * 100))%",
                            label: "Hydration",
                            color: Theme.Colors.iconBlue600
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
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.md)
                    .opacity(showSupporting ? 1 : 0)
                    .offset(y: showSupporting ? 0 : 30)

                    // MARK: - Action Buttons
                    HStack(spacing: Theme.Spacing.md) {
                        Button(action: onRetake) {
                            Text("Retake")
                                .font(Theme.Fonts.bodyBold())
                                .foregroundStyle(Theme.Colors.textOnGlass)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .glassSurface(radius: Theme.Radius.pill)
                        }
                        .buttonStyle(BouncyButtonStyle())

                        Button(action: {
                            Theme.Haptics.success()
                            onSave()
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Save Log")
                                    .font(Theme.Fonts.bodyBold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.Colors.neutral900)
                            .clipShape(Capsule())
                            .cardShadow()
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                    .opacity(showSupporting ? 1 : 0)
                }
            }
        }
        .onAppear(perform: runRevealSequence)
    }

    // MARK: - Gauge hero (ring + score)

    private var gaugeHero: some View {
        ZStack {
            // Empty track
            Circle()
                .stroke(
                    Color.white.opacity(0.55),
                    style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                )
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)

            // Filled sweep — fills to score/100
            Circle()
                .trim(from: 0, to: gaugeFill)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.iconBlue300,
                            Theme.Colors.iconBlue400,
                            Theme.Colors.iconBlue500,
                            Theme.Colors.iconBlue400
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)

            // One-shot punch when gauge tops out
            Circle()
                .stroke(Theme.Colors.iconBlue400.opacity(ringPulse ? 0 : 0.55), lineWidth: 4)
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)
                .scaleEffect(ringPulse ? 1.18 : 1.0)
                .animation(.easeOut(duration: 0.6), value: ringPulse)

            // Giant score number inside the ring
            Text("\(scoreAnimated)")
                .font(.custom("PlusJakartaSans-ExtraBold", size: 180))
                .foregroundStyle(darkScoreColor)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: ringOuterDiameter - ringThickness * 2)
        }
        .shadow(color: Theme.Colors.iconBlue500.opacity(0.22), radius: 24, x: 0, y: 10)
        .frame(width: ringOuterDiameter, height: ringOuterDiameter)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reveal sequence

    private func runRevealSequence() {
        // Reset
        gaugeFill = 0
        scoreAnimated = 0
        ringPulse = false
        showSupporting = false

        let fillDuration: Double = 0.8

        // Fill gauge to score/100
        withAnimation(.easeOut(duration: fillDuration)) {
            gaugeFill = CGFloat(percentileScore) / 100.0
        }

        // Count-up score in parallel with the fill
        animateScore(duration: fillDuration)

        // When gauge tops out: pulse + confetti + supporting content
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration) {
            ringPulse = true
            confettiStart = Date()
            Theme.Haptics.success()

            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                showSupporting = true
            }
        }
    }

    private func animateScore(duration: Double) {
        let target = percentileScore
        let steps = 25
        let interval = duration / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.easeOut(duration: interval)) {
                    scoreAnimated = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Confetti Burst

/// One-shot confetti explosion driven by a TimelineView(.animation).
/// Spawns 70 particles at the ring center (top-third of screen) that explode
/// outward, fall under gravity, and fade over ~1.6s. Restarts whenever
/// `startDate` changes (i.e. when a new analysis lands).
private struct ConfettiBurstView: View {
    let startDate: Date?

    private static let particleCount = 70
    private static let lifetime: Double = 1.6

    // Pre-generated particle params (stable across re-renders for a given start).
    private let particles: [ConfettiParticle] = (0..<ConfettiBurstView.particleCount).map { _ in
        ConfettiParticle.random()
    }

    var body: some View {
        GeometryReader { proxy in
            if let start = startDate {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    if elapsed >= 0 && elapsed <= Self.lifetime {
                        Canvas { ctx, size in
                            // Burst origin: matches gauge ring center placement.
                            // Top bar (44pt) + topPad (16pt) + hero topPad (24pt) + ring radius (150)
                            // — approximate to top quarter of the screen.
                            let origin = CGPoint(x: size.width / 2, y: size.height * 0.30)
                            let t = elapsed
                            let g: Double = 900   // gravity px/s^2

                            for p in particles {
                                // Position = origin + v0*t + 0.5*g*t^2
                                let dx = p.vx * t
                                let dy = p.vy * t + 0.5 * g * t * t
                                let x = origin.x + dx
                                let y = origin.y + dy

                                // Fade in fast, fade out toward the end.
                                let lifeFrac = t / Self.lifetime
                                let alpha = max(0, 1 - pow(lifeFrac, 2.2))

                                let r = p.radius
                                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                                var color = p.color
                                color = color.opacity(alpha)
                                ctx.fill(Path(ellipseIn: rect), with: .color(color))
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
                .id(start)   // restart timeline when start changes
            } else {
                Color.clear
            }
        }
    }
}

private struct ConfettiParticle {
    let vx: Double      // initial horizontal velocity (px/s)
    let vy: Double      // initial vertical velocity (px/s) — negative = up
    let radius: CGFloat
    let color: Color

    static func random() -> ConfettiParticle {
        // Random direction across full 360°, biased slightly upward so gravity
        // gives a nice arc.
        let angle = Double.random(in: 0..<(2 * .pi))
        let speed = Double.random(in: 280...620)
        let vx = cos(angle) * speed
        // Bias upward: subtract a bit so even "down" particles get some lift.
        let vy = sin(angle) * speed - Double.random(in: 80...220)

        let palette: [Color] = [
            Theme.Colors.good,
            Theme.Colors.iconBlue400,
            Theme.Colors.amber,
            Theme.Colors.peach,
            Theme.Colors.lavender,
            Theme.Colors.mint
        ]

        return ConfettiParticle(
            vx: vx,
            vy: vy,
            radius: CGFloat.random(in: 3...6),
            color: palette.randomElement() ?? Theme.Colors.iconBlue400
        )
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
                    .font(.system(size: 12, weight: .bold))
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
        .frame(maxWidth: .infinity)
        .glassSurface(radius: Theme.Radius.small)
    }
}


#Preview {
    CameraView(isPresented: .constant(true), showManualEntry: .constant(false))
}

