import glob

file = 'lib/features/shared/widgets/payment_sheet.dart'
with open(file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    """    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }""",
    """    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Gagal membuka URL: $e");
    }"""
)

content = content.replace(
    """        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }""",
    """        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("Gagal membuka URL: $e");
        }"""
)

with open(file, 'w', encoding='utf-8') as f:
    f.write(content)
