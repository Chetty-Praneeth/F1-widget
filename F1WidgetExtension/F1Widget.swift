import WidgetKit
import SwiftUI

@main
struct F1Widget: Widget {
    let kind: String = "F1Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOSApplicationExtension 16.0, *) {
                switch entry.widgetFamily {
                case .systemMedium:
                    MediumWidgetView(entry: entry)
                default:
                    SmallWidgetView(entry: entry)
                }
            } else {
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Next F1 Race")
        .description("Countdown to the next Formula 1 race.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
