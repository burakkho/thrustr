# Analytics Module Development Guidelines

## Working with Health Intelligence
When developing analytics features, always consider the athlete's perspective:

**Analytics Implementation Principles:**
- **Meaningful Metrics**: Focus on metrics that actually help athletes improve
- **Context-Aware Insights**: Provide insights that consider training history and goals
- **Visual Clarity**: Use charts and graphs that athletes can quickly understand
- **Actionable Recommendations**: Every insight should suggest concrete next steps

**Analytics Module Structure:**
```swift
Features/Analytics/
├── Health/                   # Health trends and intelligence analytics
├── Training/                 # Training analytics and progression tracking
├── Nutrition/               # Nutrition insights and dietary patterns
├── Charts/                  # Data visualization components
├── Components/              # Reusable analytics UI components
└── AnalyticsTabView.swift   # Main analytics navigation
```

**Key Analytics Components:**
- **AnalyticsService**: Core analytics processing and data aggregation
- **ProfileAnalyticsService**: User-specific analytics and insights generation
- **HealthIntelligenceViewModel**: Health trends and AI-powered insights
- **HealthTrendsViewModel**: Long-term health pattern analysis
- **NutritionAnalyticsViewModel**: Dietary pattern analysis and recommendations
- **TrainingAnalyticsView**: Training progression and performance analytics
- **Enhanced Analytics Cards**: Modular analytics components for different metrics

## Analytics Best Practices
- Always validate health data before analysis
- Use background processing for heavy statistical calculations
- Implement caching for frequently accessed analytics data
- Provide fallback displays when analytics data is insufficient

## Data Visualization Guidelines
- Use native iOS Charts framework for consistency
- Implement proper accessibility for all charts
- Support both light and dark themes
- Optimize for different screen sizes (iPhone, iPad)
- Provide export functionality for data

## Performance Considerations
- Lazy load historical data
- Use background contexts for heavy calculations
- Cache frequently accessed analytics
- Implement progressive data loading
- Monitor memory usage for large datasets