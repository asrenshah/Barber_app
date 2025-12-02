class AppLocalizations {
  final String lang;
  AppLocalizations(this.lang);

  String get exitTitle {
    switch (lang) {
      case 'ms':
        return "Keluar Aplikasi";
      case 'id':
        return "Keluar Aplikasi";
      case 'tl':
        return "Lumabas ng App";
      case 'th':
        return "ออกจากแอป";
      default:
        return "Exit App";
    }
  }

  String get exitMessage {
    switch (lang) {
      case 'ms':
        return "Adakah anda pasti ingin keluar?";
      case 'id':
        return "Apakah Anda yakin ingin keluar?";
      case 'tl':
        return "Sigurado ka bang gusto mong lumabas?";
      case 'th':
        return "คุณแน่ใจหรือไม่ว่าต้องการออก?";
      default:
        return "Are you sure you want to exit?";
    }
  }

  String get yes {
    switch (lang) {
      case 'ms':
      case 'id':
        return "Ya";
      case 'tl':
        return "Oo";
      case 'th':
        return "ใช่";
      default:
        return "Yes";
    }
  }

  String get no {
    switch (lang) {
      case 'ms':
      case 'id':
        return "Tidak";
      case 'tl':
        return "Hindi";
      case 'th':
        return "ไม่";
      default:
        return "No";
    }
  }

  String translate(String key) {
    switch (key) {
      case 'exit_title':
        return exitTitle;
      case 'exit_message':
        return exitMessage;
      case 'yes':
        return yes;
      case 'no':
        return no;
      default:
        return key;
    }
  }
}