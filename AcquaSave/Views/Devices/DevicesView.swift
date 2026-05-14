import SwiftUI
import SwiftData

// MARK: - Devices View

struct DevicesView: View {

    // MARK: - Environment / Queries

    @Environment(\.modelContext) private var context
    @Query(sort: \SmartDevice.name, order: .forward) private var devices: [SmartDevice]
    @Query(sort: \WaterUsageRecord.timestamp, order: .reverse) private var records: [WaterUsageRecord]

    // MARK: - UI State

    @State private var showAdd = false

    // MARK: - Derived Data

    private var summaries: [DeviceSummary] {
        DeviceAnalytics.summaries(devices: devices, records: records)
    }

    private var totalUsage: Double {
        summaries.reduce(0) { $0 + $1.totalLiters }
    }

    private var totalDevices: Int {
        devices.count
    }

    private var activeDevices: Int {
        summaries.filter { $0.usageCount > 0 }.count
    }

    private var topDevice: DeviceSummary? {
        summaries.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                devicesBackground

                ScrollView {
                    VStack(spacing: 14) {
                        header
                        overviewRow

                        if devices.isEmpty {
                            emptyStateCard
                        } else {
                            deviceList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddDeviceSheet { name, location, category in
                    context.insert(
                        SmartDevice(
                            name: name,
                            location: location,
                            categoryRawValue: category.rawValue
                        )
                    )
                    try? context.save()
                    showAdd = false
                }
            }
        }
    }

    // MARK: - Main Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your smart devices")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Track where water is used most and explore your device habits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: topMetricColumns, alignment: .center, spacing: 10) {
                topMetric(
                    title: "Devices",
                    value: "\(totalDevices)",
                    icon: "dot.radiowaves.left.and.right",
                    tint: .teal
                )

                topMetric(
                    title: "Active",
                    value: "\(activeDevices)",
                    icon: "bolt.fill",
                    tint: .green
                )

                topMetric(
                    title: "Total",
                    value: "\(Int(totalUsage)) L",
                    icon: "drop.fill",
                    tint: .blue
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overviewRow: some View {
        HStack(spacing: 12) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top device")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let topDevice {
                        Text(topDevice.name)
                            .font(.headline)

                        Text("\(Int(topDevice.totalLiters)) L")
                            .font(.system(size: 30, weight: .bold))
                            .monospacedDigit()

                        Text(topDevice.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No data yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage spread")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(totalUsage > 0 ? "Tracked" : "Waiting")
                        .font(.headline)

                    ProgressView(value: totalUsage > 0 ? 1 : 0)
                        .tint(.mint)
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)

                    Text(
                        totalUsage > 0
                        ? "Your devices are contributing to the dashboard."
                        : "Start logging usage to see trends here."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                }
            }
        }
    }

    private var emptyStateCard: some View {
        GlassCard {
            ContentUnavailableView(
                "No devices yet",
                systemImage: "dot.radiowaves.left.and.right",
                description: Text("Add your first smart device to start tracking usage across your home.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var deviceList: some View {
        VStack(spacing: 12) {
            ForEach(summaries) { summary in
                let device = devices.first(where: { $0.name == summary.name })
                let category = device?.category ?? .other

                DeviceStatsCardView(summary: summary, category: category) { liters in
                    simulateUsage(for: summary, liters: liters)
                }
            }
        }
    }

    // MARK: - Styling Helpers

    private var devicesBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.teal.opacity(0.10),
                    Color.blue.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.mint.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
    }

    private var topMetricColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 10, alignment: .center),
            count: 3
        )
    }

    private func topMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }

            VStack(spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .center)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func simulateUsage(for summary: DeviceSummary, liters: Double) {
        let record = WaterUsageRecord(
            timestamp: .now,
            liters: liters,
            deviceName: summary.name
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            context.insert(record)
            try? context.save()
        }

        HapticManager.light()
    }
}

// MARK: - Add Device Sheet

private struct AddDeviceSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var category: DeviceCategory = .other

    let onAdd: (String, String, DeviceCategory) -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Device Info") {
                    TextField("Name (e.g. Shower Head)", text: $name)
                    TextField("Location (e.g. Bathroom)", text: $location)

                    Picker("Category", selection: $category) {
                        ForEach(DeviceCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Add Device")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }

                        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

                        onAdd(
                            trimmedName,
                            trimmedLocation.isEmpty ? "Home" : trimmedLocation,
                            category
                        )
                    }
                }
            }
        }
    }
}
