//
//  SearchBar.swift
//  hackMobile
//
//  Minimal rounded search bar with reduced border contrast
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            TextField(placeholder, text: $searchText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                        .stroke(AppTheme.Colors.tertiary.opacity(0.2), lineWidth: 1)
                )
        )
        .cardShadow()
    }
}

#Preview {
    SearchBar(searchText: .constant(""), placeholder: "Search properties...")
        .padding()
        .background(AppTheme.Colors.background)
}












