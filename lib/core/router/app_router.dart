import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// احراز هویت
// ============================================================

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/login_page.dart';

// ============================================================
// Shell
// ============================================================

import '../../features/shell/main_shell.dart';
import '../../features/shell/more_page.dart';

// ============================================================
// داشبورد
// ============================================================

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/stats/presentation/stats_page.dart';



// ============================================================
// محصولات
// ============================================================

import '../../features/products/presentation/products_list_page.dart';
import '../../features/products/presentation/product_form_page.dart';

// ============================================================
// مقالات
// ============================================================

import '../../features/articles/presentation/articles_list_page.dart';
import '../../features/articles/presentation/article_form_page.dart';

// ============================================================
// سفارشات
// ============================================================

import '../../features/orders/presentation/orders_list_page.dart';
import '../../features/orders/presentation/order_detail_page.dart';

import '../../features/users/presentation/users_list_page.dart';
import '../../features/users/presentation/user_detail_page.dart';
import '../../features/users/presentation/user_form_page.dart';

import '../../features/inbox/presentation/inbox_list_page.dart';
import '../../features/inbox/presentation/inbox_detail_page.dart';

import '../../features/support/presentation/support_list_page.dart';
import '../../features/support/presentation/support_detail_page.dart';
import '../../features/messaging/presentation/messages_list_page.dart';
import '../../features/messaging/presentation/message_compose_page.dart';
import '../../features/campaign/presentation/campaign_hub_page.dart';
import '../../features/campaign/presentation/book_create_page.dart';
import '../../features/campaign/presentation/book_detail_page.dart';
import '../../features/campaign/presentation/campaign_create_page.dart';
import '../../features/wallet/presentation/wallet_list_page.dart';
import '../../features/wallet/presentation/wallet_adjust_page.dart';
import '../../features/charity/presentation/charity_hub_page.dart';
import '../../features/charity/presentation/charity_case_form_page.dart';
import '../../features/discounts/presentation/discounts_hub_page.dart';
import '../../features/discounts/presentation/coupon_create_page.dart';
import '../../features/discounts/presentation/gift_create_page.dart';
import '../../features/mass/presentation/mass_hub_page.dart';
import '../../features/purchase/presentation/purchase_list_page.dart';
import '../../features/purchase/presentation/purchase_editor_page.dart';







// ============================================================
// رسانه‌ها
// ============================================================

import '../../features/media/presentation/media_list_page.dart';
import '../../features/media/presentation/media_detail_page.dart';

// ============================================================
// نظرات
// ============================================================

import '../../features/comments/presentation/comments_list_page.dart';

// ============================================================
// درخواست‌ها
// ============================================================

import '../../features/requests/presentation/requests_list_page.dart';
import '../../features/requests/presentation/request_detail_page.dart';

// ============================================================
// یادداشت‌ها (NEW)
// ============================================================

import '../../features/notes/presentation/notes_list_page.dart';
import '../../features/notes/presentation/note_form_page.dart';
import '../../features/notes/presentation/note_detail_page.dart';

// ============================================================
// Router Provider
// ============================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    // ==========================================================
    // Redirect
    // ==========================================================

    redirect: (context, state) {
      final isLoggedIn =
          authState.status == AuthStatus.authenticated;

      final isLoading =
          authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;

      final location = state.matchedLocation;

      final isLoginRoute = location == '/login';
      final isSplashRoute = location == '/';

      // Splash is only a visual startup screen. Once AuthNotifier finishes,
      // the router decides where the user must go.
      if (isLoading) {
        return isSplashRoute ? null : '/';
      }

      if (isLoggedIn) {
        if (isSplashRoute || isLoginRoute) {
          return '/dashboard';
        }
        return null;
      }

      // Any startup/auth failure must still leave the user at login.
      if (isSplashRoute) {
        return '/login';
      }

      if (!isLoginRoute) {
        return '/login';
      }

      return null;
    },

    // ==========================================================
    // Routes
    // ==========================================================

    routes: [
      // ========================================================
      // Splash
      // ========================================================

      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),

      // ========================================================
      // Login
      // ========================================================

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ========================================================
      // Main Shell
      // ========================================================

      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // ====================================================
          // Dashboard
          // ====================================================

          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: DashboardPage(),
              );
            },
          ),

          // ====================================================
          // Products
          // ====================================================

          GoRoute(
            path: '/products',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ProductsListPage(),
              );
            },
          ),

          GoRoute(
            path: '/products/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ProductFormPage(),
              );
            },
          ),

          GoRoute(
            path: '/products/:id/edit',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              );

              return NoTransitionPage(
                child: ProductFormPage(
                  productId: id,
                ),
              );
            },
          ),

          // ====================================================
          // Articles
          // ====================================================

          GoRoute(
            path: '/articles',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ArticlesListPage(),
              );
            },
          ),

          GoRoute(
            path: '/articles/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ArticleFormPage(),
              );
            },
          ),

          GoRoute(
            path: '/articles/:id/edit',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              );

              return NoTransitionPage(
                child: ArticleFormPage(
                  articleId: id,
                ),
              );
            },
          ),

          // ====================================================
          // Orders
          // ====================================================

          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: OrdersListPage(),
              );
            },
          ),

          GoRoute(
            path: '/orders/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                    state.pathParameters['id'] ?? '',
                  ) ??
                  0;

              return NoTransitionPage(
                child: OrderDetailPage(
                  orderId: id,
                ),
              );
            },
          ),

          // ====================================================
          // Media
          // ====================================================

          GoRoute(
            path: '/media',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: MediaListPage(),
              );
            },
          ),

          GoRoute(
            path: '/media/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                    state.pathParameters['id'] ?? '',
                  ) ??
                  0;

              return NoTransitionPage(
                child: MediaDetailPage(
                  mediaId: id,
                  isEditing: false,
                ),
              );
            },
          ),

          GoRoute(
            path: '/media/:id/edit',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                    state.pathParameters['id'] ?? '',
                  ) ??
                  0;

              return NoTransitionPage(
                child: MediaDetailPage(
                  mediaId: id,
                  isEditing: true,
                ),
              );
            },
          ),

          // ====================================================
          // Comments
          // ====================================================

          GoRoute(
            path: '/comments',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: CommentsListPage(),
              );
            },
          ),

          // ====================================================
          // Requests
          // ====================================================

          GoRoute(
            path: '/requests',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: RequestsListPage(),
              );
            },
          ),

          GoRoute(
            path: '/requests/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                    state.pathParameters['id'] ?? '',
                  ) ??
                  0;

              return NoTransitionPage(
                child: RequestDetailPage(
                  id: id,
                ),
              );
            },
          ),

          // ====================================================
          // Notes (NEW)
          // ====================================================

          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: NotesListPage(),
              );
            },
          ),

          GoRoute(
            path: '/notes/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: NoteFormPage(),
              );
            },
          ),

          GoRoute(
            path: '/notes/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                    state.pathParameters['id'] ?? '',
                  ) ??
                  0;

              return NoTransitionPage(
                child: NoteDetailPage(
                  noteId: id,
                ),
              );
            },
          ),

          GoRoute(
            path: '/notes/:id/edit',
            pageBuilder: (context, state) {
              final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              );

              return NoTransitionPage(
                child: NoteFormPage(
                  noteId: id,
                ),
              );
            },
          ),

          // ====================================================
          // More
          // ====================================================

          // ====================================================
          // Users / Customers
          // ====================================================

          GoRoute(
            path: '/users',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: UsersListPage(),
              );
            },
          ),
          GoRoute(
            path: '/users/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: UserFormPage(),
              );
            },
          ),
          GoRoute(
            path: '/users/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoTransitionPage(
                child: UserDetailPage(userId: id),
              );
            },
          ),
          GoRoute(
            path: '/users/:id/edit',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoTransitionPage(
                child: UserFormPage(userId: id),
              );
            },
          ),


          // ====================================================
          // Inbox
          // ====================================================
          GoRoute(
            path: '/inbox',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: InboxListPage(),
              );
            },
          ),
          GoRoute(
            path: '/inbox/:uid',
            pageBuilder: (context, state) {
              final uid = int.tryParse(state.pathParameters['uid'] ?? '') ?? 0;
              return NoTransitionPage(
                child: InboxDetailPage(uid: uid),
              );
            },
          ),


          // ====================================================
          // Support
          // ====================================================
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: SupportListPage(),
              );
            },
          ),
          GoRoute(
            path: '/support/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoTransitionPage(
                child: SupportDetailPage(ticketId: id),
              );
            },
          ),


          // ====================================================
          // Single messaging
          // ====================================================
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: MessagesListPage(),
              );
            },
          ),
          GoRoute(
            path: '/messages/compose',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: MessageComposePage(),
              );
            },
          ),


          // ====================================================
          // Campaign
          // ====================================================
          GoRoute(
            path: '/campaign',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CampaignHubPage());
            },
          ),
          GoRoute(
            path: '/campaign/book/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: BookCreatePage());
            },
          ),
          GoRoute(
            path: '/campaign/book/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoTransitionPage(child: BookDetailPage(bookId: id));
            },
          ),
          GoRoute(
            path: '/campaign/new',
            pageBuilder: (context, state) {
              final bookId = int.tryParse(state.uri.queryParameters['bookId'] ?? '') ;
              return NoTransitionPage(
                child: CampaignCreatePage(initialBookId: bookId),
              );
            },
          ),


          // ====================================================
          // Wallet top-up admin
          // ====================================================
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: WalletListPage());
            },
          ),
          GoRoute(
            path: '/wallet/adjust',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: WalletAdjustPage());
            },
          ),


          // ====================================================
          // Charity (هم‌یاری بینایی)
          // ====================================================
          GoRoute(
            path: '/charity',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CharityHubPage());
            },
          ),
          GoRoute(
            path: '/charity/case/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CharityCaseFormPage());
            },
          ),


          // ====================================================
          // Discounts & Gifts
          // ====================================================
          GoRoute(
            path: '/discounts',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: DiscountsHubPage());
            },
          ),
          GoRoute(
            path: '/discounts/coupon/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CouponCreatePage());
            },
          ),
          GoRoute(
            path: '/discounts/gift/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: GiftCreatePage());
            },
          ),


          // ====================================================
          // Mass Message (پیام جمعی)
          // ====================================================
          GoRoute(
            path: '/mass',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: MassHubPage());
            },
          ),


          // ====================================================
          // Purchase Process (فرآیند خرید)
          // ====================================================
          GoRoute(
            path: '/purchase',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: PurchaseListPage());
            },
          ),
          GoRoute(
            path: '/purchase/new',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: PurchaseEditorPage());
            },
          ),
          GoRoute(
            path: '/purchase/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoTransitionPage(child: PurchaseEditorPage(scriptId: id));
            },
          ),


          
          
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: StatsPage());
            },
          ),
GoRoute(
            path: '/settings',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: SettingsPage());
            },
          ),
GoRoute(
            path: '/more',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: MorePage(),
              );
            },
          ),
        ],
      ),
    ],
  );
});