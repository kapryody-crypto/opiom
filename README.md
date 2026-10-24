# OPIOM Workspace — authentification Supabase

## Installation
1. Créer un projet Supabase.
2. Dans **SQL Editor**, exécuter `supabase/schema.sql`.
3. Dans **Authentication > Users**, créer le premier utilisateur avec une adresse email vérifiée.
4. Dans SQL Editor, exécuter (remplacer l'adresse) :
   ```sql
   update public.profiles set role='owner',active=true
   where id=(select id from auth.users where email='VOTRE_EMAIL');
   ```
5. Dans `opiom-espace-travail (2).html`, remplacer `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY` par l'URL et la clé **publique** du projet.
6. Héberger le HTML sur HTTPS. Ne jamais intégrer la clé `service_role` au navigateur.
7. Pour chaque collaborateur, créer son utilisateur via Supabase Authentication, puis activer son profil depuis SQL Editor. Les inscriptions publiques ne sont pas proposées.

## Fonctionnement
- Connexion par email/mot de passe avec Supabase Auth.
- Vérification de l'utilisateur et du profil actif avant d'initialiser l'application.
- Données partagées stockées dans `workspace_data`, protégées par Row Level Security.
- Déconnexion accessible dans l'application.
- Journal technique `audit_events` associé à `auth.uid()`.
- Les données initiales de démonstration sont écrites si une clé n'existe pas encore : remplacer ces données avant production.

## Limites et étapes avant production
- La gestion des rôles est encore partielle : l'interface existante n'applique pas des permissions détaillées par projet.
- Les modifications de données sont enregistrées par document JSON entier ; des écritures simultanées peuvent s'écraser. Prévoir des tables relationnelles et un contrôle de concurrence.
- Le journal d'activité visible dans l'interface reste basé sur un nom déclaré ; utiliser `audit_events` comme source d'identité vérifiée.
- L'administration des invitations et des comptes se fait encore dans la console Supabase.
- Tester les politiques RLS, les parcours de connexion/déconnexion et le comportement multi-utilisateur avant déploiement.
- Le compte propriétaire doit être promu manuellement et la configuration Supabase est nécessaire pour fonctionner.
