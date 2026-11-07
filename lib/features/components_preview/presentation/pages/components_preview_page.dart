import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_switch.dart';

class ComponentsPreviewPage extends StatefulWidget {
  const ComponentsPreviewPage({super.key});

  @override
  State<ComponentsPreviewPage> createState() => _ComponentsPreviewPageState();
}

class _ComponentsPreviewPageState extends State<ComponentsPreviewPage> {
  // Demo states
  bool _demoLampPowered = true;
  double _demoBrightness = 72;
  String _selectedFilterChip = 'Açık';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bileşen Önizleme',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondaryContainer,
                  width: 2,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/screens/nestora_profil_ve_ayarlar.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Demo Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.primaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Bileşen Önizleme Kılavuzu',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tasarım Sistemi v2.4',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: Hızlı Cihaz Kontrolü Çekmecesi
            _buildSectionHeader('1. Hızlı Cihaz Kontrolü', 'Alt Çekmece (Bottom Sheet)'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_rounded, color: AppColors.primaryContainer, size: 22),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salon Lambası',
                                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text('Salon • Akıllı Ampul', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                            ],
                          ),
                        ],
                      ),
                      NestoraSwitch(
                        value: _demoLampPowered,
                        onChanged: (v) => setState(() => _demoLampPowered = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.brightness_medium_rounded, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text('Parlaklık Seviyesi', style: AppTypography.labelSmall),
                              ],
                            ),
                            Text(
                              '%${_demoBrightness.round()}',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryContainer,
                            thumbColor: AppColors.primaryContainer,
                          ),
                          child: Slider(
                            value: _demoBrightness,
                            min: 0,
                            max: 100,
                            onChanged: (v) => setState(() => _demoBrightness = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Text('Tüm Cihaz Detaylarını Gör'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 16),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: Ekleme Seçim Çekmecesi
            _buildSectionHeader('2. Ekleme Seçim Çekmecesi', 'Aksiyon Menüsü'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ne eklemek istersin?',
                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildAddOption(
                    title: 'Cihaz Ekle',
                    subtitle: 'Evine yeni bir cihaz bağla ve yönet.',
                    icon: Icons.power_rounded,
                    iconBg: AppColors.primaryContainer,
                    iconColor: Colors.white,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildAddOption(
                    title: 'Oda Ekle',
                    subtitle: 'Evine yeni bir yaşam alanı oluştur.',
                    icon: Icons.meeting_room_rounded,
                    iconBg: AppColors.secondaryContainer,
                    iconColor: AppColors.primaryContainer,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 3: Cihaz Filtreleme Çekmecesi
            _buildSectionHeader('3. Cihaz Filtreleme Çekmecesi', 'Filtre Paneli'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cihazları Filtrele', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text('1 Aktif Filtre', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: ['Tümü', 'Açık', 'Kapalı', 'Favoriler'].map((chip) {
                      final isSel = _selectedFilterChip == chip;
                      return ChoiceChip(
                        label: Text(chip),
                        selected: isSel,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.secondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedFilterChip = chip),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 4: Silme Onay Diyalogları (2 Varyasyon)
            _buildSectionHeader('4. Silme Onay Diyalogları', '2 Varyasyon'),
            const SizedBox(height: 10),
            // Variation A
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.error),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VARYASYON A', style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          Text('Cihazı Sil', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu cihazı silmek istediğine emin misin? Bu işlem geri alınamaz ve cihazın bağlı olduğu tüm rutinler devre dışı bırakılır.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Vazgeç')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Variation B
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sensor_door_rounded, size: 20, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VARYASYON B', style: AppTypography.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          Text('Odayı Sil', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu odada kayıtlı 3 aktif cihaz bulunuyor. Odayı silmeden önce bu cihazları başka bir odaya taşıyabilir veya odasız bırakabilirsin.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Vazgeç')),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('Cihazları Yönet'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Odayı Sil'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 5: Başarı Bildirim Çubukları (Snackbars)
            _buildSectionHeader('5. Başarı Bildirimleri (Snackbars)', 'Geri Bildirim Toast'),
            const SizedBox(height: 10),
            // Toast 1
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cihaz başarıyla eklendi.',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Toast 2
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primaryContainer),
                      const SizedBox(width: 10),
                      Text(
                        'Oda başarıyla oluşturuldu.',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Geri Al',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Toast 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.published_with_changes_rounded, size: 20, color: AppColors.primaryContainer),
                      const SizedBox(width: 10),
                      Text(
                        'Değişiklikler kaydedildi.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text('Şimdi', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 6: Yeniden Kullanılabilir UI Durumları
            _buildSectionHeader('6. Yeniden Kullanılabilir UI Durumları', '3 Temel Durum'),
            const SizedBox(height: 12),
            Text('6.1 Boş Durumlar (Empty States)', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildEmptyStateCard(
                    icon: Icons.devices_other_rounded,
                    title: 'Henüz cihaz yok',
                    subtitle: 'İlk akıllı cihazını bağla.',
                    actionLabel: '+ Cihaz',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmptyStateCard(
                    icon: Icons.domain_add_rounded,
                    title: 'Henüz oda yok',
                    subtitle: 'Yeni bir alan oluştur.',
                    actionLabel: '+ Oda',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmptyStateCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Bildirim yok',
                    subtitle: 'Tüm sistemler yolunda.',
                    chipLabel: 'Sakin',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6.2 Skeleton Loading
            Text('6.2 Yükleme Durumları (Skeleton Loading)', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6))),
                            const SizedBox(height: 6),
                            Container(width: 180, height: 10, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5))),
                          ],
                        ),
                      ),
                      Container(width: 48, height: 24, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6.3 Hata Durumu
            Text('6.3 Hata Durumu (Error State)', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wifi_off_rounded, size: 28, color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  Text('Bağlantı Kurulamadı', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Ev ağına bağlanırken küçük bir aksaklık yaşandı. Lütfen yönlendiricini kontrol et veya yeniden bağlanmayı dene.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('Ağ Ayarları'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
        Text(badge, style: AppTypography.caption.copyWith(color: AppColors.secondary)),
      ],
    );
  }

  Widget _buildAddOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.secondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    String? chipLabel,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.secondary, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(actionLabel, style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          if (chipLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(chipLabel, style: AppTypography.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}
