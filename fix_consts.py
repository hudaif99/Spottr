import re

files = [
    "lib/presentation/screens/history_screen.dart",
    "lib/presentation/screens/home_screen.dart",
    "lib/presentation/screens/plan_management_screen.dart",
    "lib/presentation/screens/settings_screen.dart",
    "lib/presentation/widgets/volt_text_field.dart"
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Replace 'const Icon' with 'Icon' if it contains 'context.colors' nearby. 
    # Just do a blanket replace of 'const Icon(' with 'Icon(' since performance is not critical.
    content = content.replace('const Icon(', 'Icon(')
    content = content.replace('const Divider(', 'Divider(')
    content = content.replace('const CircularProgressIndicator(', 'CircularProgressIndicator(')
    
    # For home_screen.dart context issue
    if 'home_screen.dart' in f:
        content = content.replace('Widget _buildWeeklyStatsSection()', 'Widget _buildWeeklyStatsSection(BuildContext context)')
        content = content.replace('_buildWeeklyStatsSection(),', '_buildWeeklyStatsSection(context),')
        
    with open(f, 'w') as file:
        file.write(content)
