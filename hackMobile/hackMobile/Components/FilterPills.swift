//
//  FilterPills.swift
//  hackMobile
//
//  Soft pill filters with gentle accents
//

import SwiftUI

struct FilterPill: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? AppTheme.Colors.surface : AppTheme.Colors.textSecondary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.surface)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.clear : AppTheme.Colors.tertiary.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct FilterPills: View {
    @Binding var selectedFilter: String?
    let filters: [(key: String, title: String, icon: String?)]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(filters.enumerated()), id: \.element.key) { index, filter in
                    FilterPill(
                        filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter.key
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = selectedFilter == filter.key ? nil : filter.key
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
}

#Preview {
    FilterPills(
        selectedFilter: .constant("filter_all"),
        filters: [
            ("filter_all", "All", nil),
            ("filter_available", "Available", "checkmark.circle.fill"),
            ("filter_sold", "Sold", "xmark.circle.fill"),
            ("filter_luxury", "Luxury", "sparkles"),
            ("filter_new", "New", "star.fill")
        ]
    )
    .padding(.vertical)
    .background(AppTheme.Colors.background)
}





