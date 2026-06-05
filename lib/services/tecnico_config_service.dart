import 'package:get_storage/get_storage.dart';

class TecnicoConfigService {
  static final TecnicoConfigService instance = TecnicoConfigService._();
  TecnicoConfigService._();

  final _storage = GetStorage();

  // Chaves para Bovinos
  static const String bovToque = 'bov_toque_dias';
  static const String bovCio = 'bov_cio_dias';
  static const String bovSecagem = 'bov_secagem_dias_pre';
  static const String bovParto = 'bov_parto_dias_pre';
  static const String bovPve = 'bov_pve_dias';

  // Chaves para Ovinos/Caprinos
  static const String oviToque = 'ovi_toque_dias';
  static const String oviCio = 'ovi_cio_dias';
  static const String oviSecagem = 'ovi_secagem_dias_pre';
  static const String oviParto = 'ovi_parto_dias_pre';
  static const String oviPve = 'ovi_pve_dias';

  // Métodos para Bovinos (Padrões)
  int getBovToque() => _storage.read(bovToque) ?? 30;
  int getBovCio() => _storage.read(bovCio) ?? 21;
  int getBovSecagem() => _storage.read(bovSecagem) ?? 60;
  int getBovParto() => _storage.read(bovParto) ?? 15;
  int getBovPve() => _storage.read(bovPve) ?? 45;

  // Métodos para Ovinos/Caprinos (Padrões)
  int getOviToque() => _storage.read(oviToque) ?? 45;
  int getOviCio() => _storage.read(oviCio) ?? 21;
  int getOviSecagem() => _storage.read(oviSecagem) ?? 30;
  int getOviParto() => _storage.read(oviParto) ?? 15;
  int getOviPve() => _storage.read(oviPve) ?? 50;

  // Salvamento
  void setConfig(String key, int value) => _storage.write(key, value);
}
