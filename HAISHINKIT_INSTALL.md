# 📦 Installation de HaishinKit pour LiveStage

## Prérequis

HaishinKit est une bibliothèque Swift pour le streaming RTMP/RTSP. Elle est nécessaire pour la fonctionnalité de streaming en direct de LiveStage.

## Installation via Xcode

### Méthode 1 : Via l'interface Xcode (Recommandé)

1. Ouvrez le projet `LiveStage.xcodeproj` dans Xcode
2. Dans le menu : **File** > **Add Package Dependencies...**
3. Dans le champ de recherche, entrez :
   ```
   https://github.com/shogo4405/HaishinKit.swift
   ```
4. Sélectionnez la version **1.9.0** ou supérieure
5. Cliquez sur **Add Package**
6. Sélectionnez la target **LiveStage** et cliquez sur **Add Package**

### Méthode 2 : Modification manuelle du project.pbxproj

Si vous préférez ajouter la dépendance manuellement, ajoutez ces lignes dans `project.pbxproj` :

```swift
/* Package References */
packageReferences = (
    {
        isa = XCRemoteSwiftPackageReference;
        repositoryURL = "https://github.com/shogo4405/HaishinKit.swift";
        requirement = {
            kind = upToNextMajorVersion;
            minimumVersion = 1.9.0;
        };
    },
);
```

## Vérification de l'installation

1. Dans Xcode, allez dans **File** > **Packages** > **Resolve Package Versions**
2. Vérifiez que HaishinKit apparaît dans la liste des packages
3. Compilez le projet (⌘+B) pour vérifier qu'il n'y a pas d'erreurs

## Configuration post-installation

Après l'installation de HaishinKit, le code de `RTMPStreamManager.swift` sera automatiquement activé et prêt à l'emploi.

### Permissions requises

Assurez-vous que `Info.plist` contient les permissions suivantes (déjà ajoutées) :

- `NSCameraUsageDescription` : Pour accéder à la caméra
- `NSMicrophoneUsageDescription` : Pour accéder au microphone

## Ressources

- **Documentation HaishinKit** : https://github.com/shogo4405/HaishinKit.swift
- **Documentation RTMP** : https://www.adobe.com/devnet/rtmp.html
- **Guide YouTube Live API** : https://developers.google.com/youtube/v3/live/getting-started

## Dépannage

### Erreur : "No such module 'HaishinKit'"

**Solution** : Vérifiez que le package est bien ajouté et que vous avez résolu les dépendances.

### Erreur de compilation liée à iOS version

**Solution** : HaishinKit nécessite iOS 13.0+. Vérifiez que votre deployment target est configuré correctement.

### Performance médiocre du streaming

**Solution** : Consultez la section "Notes de Performance" dans `RTMPStreamManager.swift` pour des conseils d'optimisation.
