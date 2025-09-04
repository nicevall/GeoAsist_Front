# Feature-First Architecture Implementation

This directory implements the **feature-first organization** as recommended in the BUENAS_PRACTICAS_FLUTTER.md for optimal Claude Code compatibility.

## Structure

Each feature follows the Clean Architecture pattern:

```
features/
├── feature_name/
│   ├── domain/
│   │   ├── entities/          # Max 200 líneas por archivo
│   │   ├── repositories/      # Interfaces <100 líneas
│   │   └── use_cases/         # Un use case por archivo <150 líneas
│   ├── data/
│   │   ├── models/            # DTOs <250 líneas
│   │   ├── repositories/      # Implementaciones <350 líneas
│   │   └── data_sources/      # API/Local <300 líneas
│   ├── presentation/
│   │   ├── pages/             # Una página por archivo <250 líneas
│   │   ├── widgets/           # Widgets específicos <150 líneas
│   │   └── controllers/       # State management <300 líneas
│   └── application/
│       └── services/          # Lógica de negocio <350 líneas
```

## Features Implemented

1. **authentication** - User login, registration, email verification
2. **events** - Event creation, management, monitoring
3. **attendance** - Attendance tracking, geofencing, presence management
4. **justifications** - Absence justifications management
5. **notifications** - Push notifications, local notifications
6. **dashboard** - User dashboards by role
7. **settings** - App settings and preferences