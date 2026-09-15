/// Shared user-visible copy, in one place.
///
/// Screen-specific prose stays with its screen — hoisting every sentence
/// here would trade locality for a phonebook. What lives here is copy
/// repeated across screens: common actions, permission-gating states, save
/// failures, and placeholders. One wording fix lands everywhere at once,
/// and a future localization pass starts from this file.
library;

import 'app_limits.dart';

abstract final class AppStrings {
  // -------------------------------------------------------------------------
  // Common actions
  // -------------------------------------------------------------------------

  static const save = 'Save';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static const retry = 'Retry';
  static const close = 'Close';
  static const clear = 'Clear';
  static const add = 'Add';
  static const edit = 'Edit';
  static const done = 'Done';
  static const exportPdf = 'Export PDF';
  static const exportExcel = 'Export Excel';

  // -------------------------------------------------------------------------
  // Permission gating
  // -------------------------------------------------------------------------

  static String accessDeniedFor(String feature) => '$feature Access Denied';
  static const offlineMode = 'Offline Mode';
  static const offlineSubtitle =
      'Permission check unavailable. Some features may be disabled.';
  static const noPermission = 'No permission';
  static const accessDenied = 'Access Denied';
  static const permissionDeniedHint =
      'You do not have permission to access this screen.';
  static const offlinePermissionsHint =
      'Permission check unavailable while offline.\n'
      'This feature may be disabled in offline mode.';
  static const lackingPermission = 'You lack permission for this action';
  static const lackingScreenPermission =
      'You lack permission to access this screen';
  static const offlinePermissionsTooltip = 'Offline mode: permissions unavailable';
  static const offlineCheckUnavailable = 'Offline: permission check unavailable';
  static const permissionCheckFailed = 'Permission check failed';
  static const errorTitle = 'Error';

  // -------------------------------------------------------------------------
  // Save failures
  // -------------------------------------------------------------------------

  static String saveFailed(Object error) => 'Could not save: $error';

  // -------------------------------------------------------------------------
  // Placeholders
  // -------------------------------------------------------------------------

  static const unknown = 'Unknown';
  static const unknownItem = 'Unknown item';

  // -------------------------------------------------------------------------
  // Photos
  // -------------------------------------------------------------------------

  static const uploadImage = 'Upload image';
  static const imageHint =
      'PNG or JPG · up to ${AppLimits.imageMaxBytes ~/ (1024 * 1024)} MB';
  static const removeImage = 'Remove image';
  static const couldNotOpenImagePicker = 'Could not open the image picker';

  // -------------------------------------------------------------------------
  // Navigation destinations
  // -------------------------------------------------------------------------

  static const navDashboard = 'Dashboard';
  static const navPos = 'POS';
  static const navSales = 'Sales';
  static const navCustomers = 'Customers';
  static const navReorders = 'Reorders';
  static const navProduction = 'Production';
  static const navSuppliers = 'Suppliers';
  static const navCouriers = 'Couriers';
  static const navFinance = 'Finance';
  static const navReports = 'Reports';
  static const navInsights = 'Insights';
  static const navInventory = 'Inventory';
  static const navStaff = 'Staff';
  static const navSettings = 'Settings';
  static const navMore = 'More';
  static const navMoreDestinations = 'More destinations';
  static const navGoTo = 'Go to';
  static const themeFollowSystem = 'Theme: follow system';
  static const followSystem = 'Follow system';
  static const lightTheme = 'Light theme';
  static const darkTheme = 'Dark theme';

  // -------------------------------------------------------------------------
  // Top bar
  // -------------------------------------------------------------------------

  static const chatWithAssistant = 'Chat with Assistant';
  static const help = 'Help';
  static const helpComingSoon = 'Help center coming soon';
  static const accountAndOptions = 'Account & options';
  static const authTestSplash = 'Splash Screen';
  static const authTestOtp = 'OTP Login';
  static const authTestOnboarding = 'Onboarding';
  static const authTestSetPin = 'Set PIN';
  static const authTestPinUnlock = 'PIN Unlock';
  static const authTestProfiles = 'Profile Picker';
  static const logout = 'Logout';
  static const notifications = 'Notifications';
  static const filterLabel = 'Filter';
  static const sortTooltip = 'Sort';
  static String sortAscending(String option) => '$option — ascending';
  static String sortDescending(String option) => '$option — descending';
  static const sortFallback = 'Sort';
  static const filtersTitle = 'Filters';
  static const noResults = 'No results';
  static String showingRange(int first, int last, int total) =>
      'Showing $first–$last of $total';
  static const previousPage = 'Previous page';
  static const nextPage = 'Next page';
  static String pagerPosition(int page, int count) => '$page / $count';
  static const tryDifferentSearch =
      'Try a different search or clear your filters.';
  static const rangeMin = 'Min';
  static const rangeMax = 'Max';
  static const rangeSeparator = '–';
  static const rowActions = 'Row actions';
  static const copyPath = 'Copy path';

  // -------------------------------------------------------------------------
  // Chat assistant & cash tender
  // -------------------------------------------------------------------------

  static const assistantTitle = 'Restaurant Assistant';
  static const savedTick = 'Saved';
  static const frontOfHouse = 'Front of house';
  static const noRole = 'No role';
  static const startConversation = 'Start a conversation';
  static const askAboutOrders =
      'Ask me about orders, inventory, sales, and more';
  static const typeMessage = 'Type your message...';
  static const amountTendered = 'Amount tendered';
  static const exactChip = 'Exact';
  static String quickChip(String amount) => '+$amount';
  static const stillOwing = 'Still owing';
  static const changeDue = 'Change due';
  static const subtotalLabel = 'Subtotal';
  static String discountLabel(String percent) => 'Discount ($percent)';
  static String discountValue(String amount) => '−$amount';
  static String taxLabel(String percent) => 'Tax ($percent)';
  static const totalLabel = 'Total';
  static const methodLabel = 'Method';
  static const tenderedLabel = 'Tendered';

  // -------------------------------------------------------------------------
  // POS: customer picker
  // -------------------------------------------------------------------------

  static const walkInAttachCustomer = 'Walk-in — attach a customer';
  static const unknownInitial = '?';
  static const change = 'Change';
  static const removeCustomer = 'Remove customer';
  static const attachCustomer = 'Attach a customer';
  static const searchNameOrPhone = 'Search name or phone';
  static const noCustomerWalkIn = 'No customer (walk-in)';
  static const noMatchingCustomers = 'No matching customers';
  static const addNewCustomer = 'Add new customer';

  // -------------------------------------------------------------------------
  // POS: menu, cart, charge
  // -------------------------------------------------------------------------

  static const soldOutBadge = "86'd";
  static String quantityBadge(int? quantity) => '$quantity';
  static const cartNoItems = 'No items';
  static String cartItemCount(int count) =>
      '$count ${count == 1 ? 'item' : 'items'}';
  static const cartView = 'View';
  static const decrease = 'Decrease';
  static const remove = 'Remove';
  static const increase = 'Increase';
  static String stepperQuantity(int quantity) => '$quantity';
  static const takePayment = 'Take payment';
  static const chargeCustomer = 'Customer';
  static const chargePaymentMethod = 'Payment method';
  static String orderCharged(
    String id,
    String total,
    String method,
    String changePart,
    String receiptPart,
  ) =>
      '$id charged — $total by $method$changePart$receiptPart';
  static String chargeChangePart(String change) => ' · $change change';
  static String chargeReceiptPart(String receipt) =>
      ' · receipt $receipt printing';
  static const cashReceived = 'Cash received';
  static String chargeTotal(String total) => 'Charge $total';
  static String terminalNotice(String method) =>
      'Complete the ${method.toLowerCase()} payment on the terminal, '
      'then charge to record it.';
  static String cartLineQuantity(int quantity) => '× $quantity';
  static String cartLineEach(String price) => '$price each';
  static const searchMenu = 'Search menu';
  static const searchMenuItems = 'Search menu items, categories…';
  static const clearSearch = 'Clear';
  static const scanBarcode = 'Scan barcode';
  static const scannerNotConnected = 'Scanner not connected';
  static const cashierRole = 'Cashier';
  static const takingPayment = 'Taking payment';
  static const currentOrder = 'Current order';
  static const clearOrder = 'Clear order';
  static const assignTable = 'Assign table';
  static const counterNoTable = 'Counter (no table)';
  static String tableNumber(int i) => 'Table $i';
  static const counter = 'Counter';
  static String tableLabel(Object table) => 'Table $table';
  static const noItemsYet = 'No items yet';
  static const tapMenuToStart = 'Tap a menu item to start this order.';
  static const charge = 'Charge';
  static const confirm = 'Confirm';
  static const confirmPayment = 'Confirm payment';
  static const applyDiscount = 'Apply discount';
  static const noDiscount = 'No discount';
  static String orderTypeTable(String orderType, Object? table) =>
      table == null ? orderType : '$orderType · $table';

  // -------------------------------------------------------------------------
  // POS screen
  // -------------------------------------------------------------------------

  static const noMenuHere = 'Nothing on the menu here';
  static const noMatches = 'No matches';
  static const noItemsInCategory = 'This category has no items yet.';
  static String nothingMatches(String query) =>
      'Nothing matches “$query” in this category.';
  static const clearFilters = 'Clear filters';
  static String ticketTable(String table) => 'Table $table';

  // -------------------------------------------------------------------------
  // Auth: profile / PIN / OTP
  // -------------------------------------------------------------------------

  static String saveDetailsFailed(Object e) => 'Could not save your details: $e';
  static const tellUsWhoYouAre = 'Tell us who you are';
  static const profileSubtitle = 'This appears on receipts, invites and the staff list';
  static const fullName = 'Full name';
  static const nameExample = 'Amina Hassan';
  static const emailLabel = 'Email';
  static const emailHelper = 'Optional — used for receipts and account recovery';
  static const emailExample = 'amina@venue.com';
  static const invalidEmail = 'Enter a valid email address';
  static const continueAction = 'Continue';
  static String sendCodeFailed(Object e) => 'Failed to send code: $e';
  static const enterPhoneNumber = 'Enter your phone number';
  static const codeNotRight = 'That code is not right. Check your messages.';
  static const enterYourCode = 'Enter your code';
  static const signIn = 'Sign in';
  static String codeSentTo(String phone) => 'We sent a 6-digit code to $phone';
  static const useRegisteredPhone = 'Use the phone number your manager registered';
  static const backToProfiles = 'Back to profiles';
  static const phoneNumber = 'Phone number';
  static const phoneExample = '6XXXXXXXX or 7XXXXXXXX';
  static const dialCode = '+255';
  static const sendCode = 'Send code';
  static const verifying = 'Verifying';
  static String resendIn(int seconds) => 'Resend code in ${seconds}s';
  static const resendCode = 'Resend code';
  static const changeNumber = 'Change number';
  static const codeHint = 'We texted you a 6-digit code';
  static const pointOfSale = 'Point of sale';
  static const preparingTerminal = 'Preparing your terminal';
  static const whoIsWorking = "Who's working?";
  static const noSignInsYet = 'No one has signed in on this terminal yet';
  static const chooseProfile = 'Choose your profile to unlock the till';
  static const signInDifferently = 'Not your device? Sign in differently';
  static const notSignedInYet = 'Not signed in yet';
  static const addAccount = 'Add account';
  static const addAccountSubtitle = 'Sign in with a phone number';
  static const pinsDidNotMatch = 'Those PINs did not match. Start again.';
  static String pinSaveFailed(Object e) => 'Failed to save PIN: $e';
  static const chooseNewPin = 'Choose a new PIN';
  static const confirmYourPin = 'Confirm your PIN';
  static const createYourPin = 'Create your PIN';
  static const enterSamePin = 'Enter the same six digits again';
  static const pinUnlockHint = "You'll use this to unlock the POS quickly";
  static const pinSaved = 'PIN saved';
  static const signInWithOtp = 'Sign in with OTP instead';
  static const switchProfile = 'Switch profile';
  static String enterPin(int length) => 'Enter your $length-digit PIN';
  static const incorrectPinLast = 'Incorrect PIN — last attempt';
  static String incorrectPinLeft(int left) =>
      'Incorrect PIN, try again ($left attempts left)';
  static const tooManyAttempts = 'Too many attempts';
  static const tillLockedMoment =
      'For everyone\'s safety the till is locked for a moment.';
  static const secondRemaining = 'second remaining';
  static const secondsRemaining = 'seconds remaining';
  static String countdownSeconds(int seconds) => '$seconds';

  // -------------------------------------------------------------------------
  // Auth: marketing aside / steps / keypad
  // -------------------------------------------------------------------------

  static const asideOrderFast = 'Take an order in three taps';
  static const asideSplitBill = 'Split a bill without the maths';
  static const asideCashUp = 'Cash up in under a minute';
  static const asideHeadline = 'The till your\nfloor staff\nactually like.';
  static const asideSupporting =
      'Orders, payments and takings in one place — on the counter, '
      'on a tablet, or behind the bar.';
  static String stepOf(int step, int count) => '$step of $count';
  static String stepNumber(int index) => '${index + 1}';
  static String copyrightNotice(int year, String store) => '© $year $store';
  static const deleteKey = 'Delete';

  // -------------------------------------------------------------------------
  // Onboarding
  // -------------------------------------------------------------------------

  static const obYourBusiness = 'Your business';
  static const obYourBusinessBlurb = 'Name, type and logo';
  static const obWhereYouTrade = 'Where you trade';
  static const obWhereYouTradeBlurb = 'Address and contact';
  static const obHowYouCharge = 'How you charge';
  static const obHowYouChargeBlurb = 'Currency, tax and orders';
  static const obYourTeam = 'Your team';
  static const obYourTeamBlurb = 'Invite the people who work here';
  static const obDuplicateBusiness =
      'You already have a business registered to this account.';
  static const obSetupFailed =
      'Something went wrong finishing setup — please try again.';
  static String obPartialInvite(String failed) =>
      'Set up, but couldn\'t invite $failed — try again from Staff.';
  static const obTellUsTitle = 'Tell us about your business';
  static const obWhereTitle = 'Where do you trade?';
  static const obPrefsTitle = 'A few preferences';
  static const obTeamTitle = 'Who else works here?';
  static const obTellUsSubtitle = 'This appears on receipts and across the app';
  static const obWhereSubtitle = 'You can add more locations later';
  static const obPrefsSubtitle = 'All of these can be changed in Settings';
  static const obTeamSubtitle = 'They will get an invite to set up their own PIN';
  static const back = 'Back';
  static const finishSetup = 'Finish setup';
  static const sendOneInvite = 'Send 1 invite & finish';
  static String sendInvites(int count) => 'Send $count invites & finish';
  static const addLogo = 'Add logo';
  static const businessName = 'Business name';
  static const businessNameExample = 'The Copper Fig';
  static const businessType = 'Business type';
  static const cuisineType = 'Cuisine type';
  static const cuisineHelper = 'Optional — shown to customers browsing the menu';
  static const cuisineExample = 'Italian, Swahili, Grill…';
  static const licenseDoc = 'License / registration document';
  static const licenseDocHelper =
      'Optional — paste a link to where it\'s hosted';
  static const urlExample = 'https://…';
  static const locationName = 'Location name';
  static const locationNameHelper = 'What staff call this site';
  static const locationExample = 'Riverside';
  static const addressLabel = 'Address';
  static const addressExample = '84 Riverside Walk, San Francisco';
  static const phoneLabel = 'Phone';
  static const currencyLabel = 'Currency';
  static const currencyHelper = 'Formats every amount in the app';
  static String currencyOption(String description, String label) =>
      '$description ($label)';
  static const taxRate = 'Tax rate';
  static const taxHelper = 'Applied to every ticket. Prices will read as ';
  static String taxPreview(String sample) => '$taxHelper$sample';
  static const taxExample = '8.25';
  static const percentSuffix = '%';
  static const taxRangeError = 'Enter a rate between 0 and 100';
  static const taxId = 'Tax ID';
  static const taxIdHelper =
      'Optional — VAT/GST registration number, printed on receipts';
  static const taxIdExample = 'TIN-123456789';
  static const regNumber = 'Business registration / license number';
  static const optional = 'Optional';
  static const regNumberExample = 'BRN-000000';
  static const defaultOrderType = 'Default order type';
  static const addAnother = 'Add another';
  static String teammate(int index) => 'Teammate ${index + 1}';
  static const removeTeammate = 'Remove';
  static const teammateName = 'Name';
  static const teammateNameExample = 'Marco Rossi';
  static const teammateEmailExample = 'marco@venue.com';
  static const inviteSentToNumber = 'Their invite is sent to this number';
  static const roleLabel = 'Role';
  static const roleHelper = 'Sets what they can reach on the till';
  static const noRushInvites =
      'No rush — you can invite people from Staff later.';

  // -------------------------------------------------------------------------
  // Inventory: stock dialogs (shared)
  // -------------------------------------------------------------------------

  static const quantityLabel = 'Quantity';
  static const quantityHint = '0';
  static const notesLabel = 'Notes';
  static const notesHint = 'Anything worth recording';
  static String stockOnHand(
    String sku,
    String quantity,
    String unit,
  ) =>
      '$sku · $quantity $unit in stock';

  // -------------------------------------------------------------------------
  // Inventory: production history
  // -------------------------------------------------------------------------

  static const productionTitle = 'Production';
  static const filterByDate = 'Filter by date';
  static const recordAction = 'Record';
  static const runsMetric = 'Runs';
  static const recordedProductions = 'Recorded productions';
  static const adjustedMetric = 'Adjusted';
  static const portionsDiffered = 'Portions differed';
  static const runsCount = 'Runs';
  static String runsWithCount(int count) => 'Runs ($count)';
  static const noRunsYet = 'No production runs yet';
  static const recordFromMenuItem = 'Record one from a menu item to see it here';
  static const whatMaking = 'What are you making?';
  static const noRecipesYet =
      'No recipes yet — define one for a menu item first, then come back '
      'to record the run.';
  static String recipeSubtitle(int count, String name) =>
      '$count ingredients · makes $name';
  static const adjustedBadge = 'Adjusted';
  static String tileDetail(
    String leadingQuantity,
    String unit,
    String name,
    String recorded,
    String sellable,
  ) =>
      '$leadingQuantity $unit $name→ $recorded × $sellable';
  static String tileDate(String date, bool adjusted, String suggested) =>
      '$date${adjusted ? ' · suggested $suggested' : ''}';
  static String recordedAt(String date) => 'Recorded $date';
  static const ellipsis = '…';
  static String dateChip(String from, String to) => '$from – $to';
  static String outputValue(String recorded, String sellable) =>
      '$recorded × $sellable';
  static const outputLabel = 'Output';
  static String suggestedWas(String quantity) => 'Suggested was $quantity';
  static String portionDiff(String quantity, bool over) =>
      '$quantity ${over ? 'over' : 'under'}';
  static const consumedSection = 'Consumed';
  static const closeAction = 'Close';

  // -------------------------------------------------------------------------
  // Inventory: reorders
  // -------------------------------------------------------------------------

  static const reordersTitle = 'Reorders';
  static const pendingMetric = 'Pending';
  static const awaitingDelivery = 'Awaiting delivery';
  static const receivedMetric = 'Received';
  static const stockAdded = 'Stock added';
  static const onOrderMetric = 'On order';
  static const totalValueMetric = 'Total value';
  static String pendingCount(int count) => 'Pending ($count)';
  static String receivedCount(int count) => 'Received ($count)';
  static String cancelledCount(int count) => 'Cancelled ($count)';
  static const noReordersYet = 'No reorders yet';
  static const receiveReorderTitle = 'Receive this reorder?';
  static const receiveReorderBody =
      'This cannot be undone.';
  static String receiveReorderAdds(String quantity, String unit) =>
      'This adds $quantity $unit to stock. $receiveReorderBody';
  static const receiveAction = 'Receive';
  static const reorderReceivedMessage = 'Reorder received — stock updated';
  static String receiveFailed(Object e) => 'Could not receive: $e';
  static const cancelReorderTitle = 'Cancel this reorder?';
  static const cannotBeUndone = 'This cannot be undone.';
  static const keepIt = 'Keep it';
  static const cancelReorderAction = 'Cancel reorder';
  static const reorderCancelledMessage = 'Reorder cancelled';
  static String cancelFailed(Object e) => 'Could not cancel: $e';
  static const unknownSupplier = 'Unknown supplier';
  static String reorderTileSubtitle(
    String quantity,
    String unit,
    String? supplier,
  ) =>
      '$quantity $unit from ${supplier ?? unknownSupplier}';
  static const unitCostColumn = 'Unit Cost';
  static const totalColumn = 'Total';
  static const expectedLabel = 'Expected';
  static const receivedLabel = 'Received';
  static const cancelledLabel = 'Cancelled';
  static String notesLine(String notes) => 'Notes: $notes';

  // -------------------------------------------------------------------------
  // Inventory: groceries & menu items lists
  // -------------------------------------------------------------------------

  static const groceriesTitle = 'Groceries';
  static const menuItemsTitle = 'Menu items';
  static String groceriesSubtitle(int total, int categories) =>
      '$total raw materials tracked across $categories categories';
  static String menuItemsSubtitle(int total) =>
      '$total items available for sale at the till';
  static String fullyStocked(int count) => '$count fully stocked';
  static const nothingOutOfStock = 'Nothing out of stock';
  static String outOfStockTrend(int count) => '$count out of stock';
  static const allLinesCovered = 'All lines covered';
  static const needsDelivery = 'Needs a delivery';
  static const atLastKnownCost = 'At last-known cost';
  static String exportCategories(int count) => '$count categories';
  static const exportAny = 'any';
  static String exportStockRange(String min, String max) =>
      'stock $min–$max';
  static String exportMatching(String search) => 'matching "$search"';
  static const exportAllGroceries = 'All groceries';
  static const exportAllMenuItems = 'All menu items';
  static String exportFiltered(String parts) => 'Filtered by $parts';
  static const availableAtTill = 'Available at the till';
  static const noDemoSales = 'No demo sales yet';
  static String demoTopSeller(Object units) => '$units sold · last 7 days, demo data';
  static const emDash = '—';
  static const last7DaysDemo = 'Last 7 days, demo data';
  static const groceryItemsMetric = 'Grocery items';
  static const searchItemsSkuSupplier = 'Search items, SKU or supplier';
  static const searchItemsCategory = 'Search items or category';
  static const nameColumn = 'Name';
  static const itemColumn = 'Item';
  static const categoryColumn = 'Category';
  static const stockColumn = 'Stock';
  static const unitColumn = 'Unit';
  static const reorderAtColumn = 'Reorder at';
  static const statusColumn = 'Status';
  static const priceColumn = 'Price';
  static const activeColumn = 'Active';
  static const viewDetail = 'View detail';
  static const editItem = 'Edit item';
  static const adjustStock = 'Adjust stock';
  static const createReorder = 'Create reorder';
  static const logWaste = 'Log waste';
  static const transferStock = 'Transfer stock';
  static const deleteAction = 'Delete';
  static String deleteItemTitle(String name) => 'Delete $name?';
  static const deleteGroceryBody =
      'The item and its stock count will be removed from inventory. '
      'This cannot be undone.';
  static const deleteMenuItemBody =
      'The item will be removed from the menu and inventory. '
      'This cannot be undone.';
  static String itemDeleted(String name) => '$name deleted';
  static String deleteFailed(Object e) => 'Could not delete: $e';
  static const notTracked = 'Not tracked';
  static const archivedBadge = 'Archived';
  static const activeBadge = 'Active';
  static const notForSale = 'Not for sale';
  static const topSeller = 'Top seller';
  static const menuRevenue = 'Menu revenue';
  static const addGroceryItem = 'Add grocery item';
  static const addMenuItem = 'Add menu item';
  static const addItem = 'Add item';
  static const belowThreshold = 'Below threshold';
  static const outOfStockMetric = 'Out of stock';
  static const stockValueMetric = 'Stock value';

  // -------------------------------------------------------------------------
  // Inventory: item detail
  // -------------------------------------------------------------------------

  static const restoreItem = 'Restore item';
  static const archiveItem = 'Archive item';
  static const deleteItem = 'Delete item';
  static const deleteItemBodyFull =
      'The item, its stock count and its entire movement history will be '
      'removed. This cannot be undone.';
  static String itemArchived(String name) => '$name archived';
  static String itemRestored(String name) => '$name restored';
  static const moreActions = 'More actions';
  static const currentStock = 'Current stock';
  static const unitCostLabel = 'Unit cost';
  static const inventoryValue = 'Inventory value';
  static const atCost = 'At cost';
  static const lowStockAt = 'Low stock at';
  static const warnAtOrBelow = 'Warn at or below';
  static String perUnit(String unit) => 'per $unit';
  static const notSet = 'Not set';
  static const atTheTill = 'At the till';
  static const setPriceForMargin = 'Set a price to see margin';
  static const perItemSold = 'Per item sold';
  static const availableValue = 'Available';
  static const notListed = 'Not listed';
  static const showingAtTill = 'Showing at the till';
  static const archivedNoPrice = 'Archived or no price set';
  static String movementsCount(int count) => '$count movements';
  static const noMovementsRecorded = 'No movements recorded yet';
  static const aboutThisItem = 'About this item';
  static const noDescription =
      'No description added yet. Use Edit to add one.';
  static const itemTypeGrocery = 'Grocery';
  static const itemTypeMenuItem = 'Menu item';
  static const itemTypeBoth = 'Bought and sold';
  static const notForSaleTill =
      'Not for sale — set a selling price to add it';
  static String availableForSale(String price) =>
      'Available for sale ($price)';
  static const sellingPrice = 'Selling price';
  static const costBasis = 'Cost basis';
  static const marginLabel = 'Margin';
  static const posAvailability = 'POS availability';
  static const editRecipe = 'Edit recipe';
  static const addRecipe = 'Add recipe';
  static const recordProduction = 'Record production';
  static const stockHistory = 'Stock history';
  static const whenColumn = 'When';
  static const typeColumn = 'Type';
  static const changeColumn = 'Change';
  static const balanceColumn = 'Balance';
  static const byColumn = 'By';
  static const noMovementsYet = 'No movements recorded yet';
  static const aboutItem = 'About this item';
  static const itemTypeLabel = 'Item type';
  static const groceryType = 'Grocery';
  static const menuItemType = 'Menu item';
  static const bothType = 'Bought and sold';
  static const skuLabel = 'SKU';
  static const supplierLabel = 'Supplier';
  static const countedIn = 'Counted in';
  static const stockTracking = 'Stock tracking';
  static const onValue = 'On';
  static const offValue = 'Off';
  static const lastCounted = 'Last counted';
  static const neverCounted = 'Never';
  static const posMenu = 'POS menu';
  static String itemNotFound(String id) => 'Item $id not found';
  static const backToInventory = 'Back to inventory';

  // -------------------------------------------------------------------------
  // Inventory: production / waste / transfer / adjust dialogs
  // -------------------------------------------------------------------------

  static const amountPositive = 'Enter an amount greater than zero';
  static const confirmedPositive = 'Confirmed output must be greater than zero';
  static String productionRecorded(String quantity, String name) =>
      'Recorded $quantity × $name';
  static String productionRecordedAdjusted(
    String quantity,
    String name,
    String suggested,
  ) =>
      'Recorded $quantity × $name (suggested $suggested)';
  static String recordFailed(String message) => 'Could not record: $message';
  static const recordProductionTitle = 'Record production';
  static const measuredIngredient = 'Measured ingredient';
  static const measuredHelper = 'What you actually put on the scale';
  static const quantityUsed = 'Quantity used';
  static const suggestedOutput = 'Suggested output';
  static const confirmedOutput = 'Confirmed output';
  static const acceptSuggestionHint = 'Leave blank to accept the suggestion';
  static const sameAsSuggested = 'Same as suggested';
  static const willConsume = 'Will consume';
  static String ingredientOption(String name, String unit) => '$name ($unit)';
  static String makesRecipe(String name, String needs) =>
      'Makes $name · per unit needs $needs';
  static String consumptionLine(String needed, String unit, String onHand) =>
      '$needed $unit · $onHand in stock';
  static const wasteReasonExpired = 'Expired';
  static const wasteReasonSpoiled = 'Spoiled';
  static const wasteReasonPrep = 'Prep error';
  static const wasteReasonDropped = 'Dropped / damaged';
  static const wasteReasonOther = 'Other';
  static String onlyInStock(String quantity, String unit) =>
      'Only $quantity $unit in stock';
  static String wasteLogged(String amount, String unit, String name) =>
      '$amount $unit of $name logged as waste';
  static String wasteFailed(Object e) => 'Could not log waste: $e';
  static String wastePhotoEvidence(String name) => 'Photo: $name';
  static const quantityWasted = 'Quantity wasted';
  static const remainingAfterWaste = 'Remaining after waste';
  static const wasteReasonLabel = 'Waste reason';
  static const wasteNotesHint = 'e.g. left out of the chiller overnight';
  static const photoLabel = 'Photo';
  static const photoClaimHelper = 'Optional — useful for a supplier claim';
  static const addPhoto = 'Add photo';
  static const transferTo = 'Transfer to';
  static const thisStore = 'this store';
  static String movingOutOf(String? store) =>
      'Moving out of ${store ?? thisStore}';
  static const selectLocation = 'Select a location';
  static const quantityToTransfer = 'Quantity to transfer';
  static const remainingAtStore = 'Remaining at this store';
  static const transferNotesHint = 'e.g. covering their Friday service';
  static String transferNoteTo(String destination) => 'To $destination';
  static String transferNoteToWith(String destination, String note) =>
      'To $destination · $note';
  static String transferDone(
    String amount,
    String unit,
    String item,
    String destination,
  ) =>
      '$amount $unit of $item transferred to $destination';
  static String transferFailed(Object e) => 'Could not transfer stock: $e';
  static const adjustType = 'Adjustment type';
  static const addStockOption = 'Add stock';
  static const deliveryOrFound = 'Delivery or found';
  static const removeStockOption = 'Remove stock';
  static const correctionOrLoss = 'Correction or loss';
  static const newStockLevel = 'New stock level';
  static const reasonLabel = 'Reason';
  static const adjustReasonAdd = 'Restock';
  static const adjustReasonRecount = 'Recount / correction';
  static const adjustReasonDamaged = 'Damaged';
  static const adjustReasonOther = 'Other';
  static const confirmAdjustment = 'Confirm adjustment';
  static String newLevelLabel(String quantity, String unit) =>
      '$quantity $unit';
  static String adjustReasonWith(String label, String note) => '$label · $note';
  static String adjustedTo(String name, String level) =>
      '$name adjusted to $level';
  static String adjustFailed(Object e) => 'Could not adjust stock: $e';
  static const adjustNotesHint = 'e.g. counted with Marco after close';
  static const everyIngredientPositive =
      'Every ingredient needs an amount greater than zero';
  static const ingredientOnce =
      'Each ingredient only once — change the amount instead';
  static String recipeSaved(String name, bool isEdit) =>
      isEdit ? '$name recipe saved' : '$name recipe added';
  static String recipeDeletedLine(String name) => '$name recipe deleted';
  static String deleteRecipeBody(String name, int lines) =>
      'The $name recipe and its $lines ingredient lines will be removed. '
      'Recorded production runs keep their history. This cannot be undone.';
  static const editRecipeTitle = 'Edit recipe';
  static const addRecipeTitle = 'Add recipe';
  static const saveChanges = 'Save changes';
  static const addRecipeAction = 'Add recipe';
  static const menuItemProduces = 'Menu item';
  static const recipeProducesHelper = 'What this recipe produces';
  static const selectHint = 'Select';
  static const recipeName = 'Recipe name';
  static const recipeNameExample = 'e.g. Pilau';
  static const recipeNameHelper = 'Shown on production runs';
  static const recipeNameDefault = 'Defaults to the menu item\u2019s name';
  static const ingredientsSection = 'Ingredients';
  static const addIngredient = 'Add';
  static const ingredientHint = 'Ingredient';
  static const removeIngredient = 'Remove ingredient';
  static const deleteRecipeTitle = 'Delete this recipe?';
  static const keepAction = 'Keep';
  static const stockStatusLabel = 'Stock status';
  static const stockQuantityLabel = 'Stock quantity';
  static const groceriesTab = 'Groceries';
  static const menuItemsTab = 'Menu items';

  // -------------------------------------------------------------------------
  // Suppliers
  // -------------------------------------------------------------------------

  static const suppliersTitle = 'Suppliers';
  static const suppliersSubtitle =
      'Vendors this business orders restock inventory from';
  static const addSupplier = 'Add supplier';
  static const totalSuppliers = 'Total suppliers';
  static const activeVendorRecords = 'Active vendor records';
  static const searchSupplier = 'Search by name, phone, or email';
  static const editAction = 'Edit';
  static String deleteSupplierTitle(String name) => 'Delete $name?';
  static const deleteSupplierBody =
      'This supplier record will be removed. Past reorders keep their '
      'attribution. This cannot be undone.';
  static String supplierDeleted(String name) => '$name deleted';
  static const phoneColumn = 'Phone';
  static const emailColumn = 'Email';
  static const editSupplier = 'Edit supplier';
  static const addSupplierTitle = 'Add supplier';
  static const supplierInfo = 'Supplier info';
  static const supplierNameHint = 'Supplier or company name';
  static const enterName = 'Enter a name';
  static const supplierPhoneExample = '+1 (555) 123-4567';
  static const supplierEmailExample = 'orders@supplier.com';
  static const addressHint = 'Street address (optional)';
  static const notesLabel2 = 'Notes';
  static const supplierNotesHint = 'Delivery notes, account number...';
  static String supplierSaved(String name, bool isEdit) =>
      isEdit ? '$name updated' : '$name added';

  // -------------------------------------------------------------------------
  // Item form
  // -------------------------------------------------------------------------

  static const editItemTitle = 'Edit item';
  static const addItemTitle = 'Add item';
  static const whatAdding = 'What are you adding?';
  static const chooserSubtitle =
      'This decides which fields the form leads with — nothing here is final.';
  static const groceryOption = 'Grocery';
  static const groceryOptionBlurb = 'A raw material you stock and use';
  static const menuItemOption = 'Menu item';
  static const menuItemOptionBlurb = 'Something you sell at the till';
  static const bothOptionBlurb =
      'This item is both bought and sold — e.g. a bottled drink';
  static const changeType = 'Change';
  static const basicInfo = 'Basic info';
  static const pricingStock = 'Pricing & stock';
  static const statusSection = 'Status';
  static const photoSection = 'Photo';
  static const itemNameLabel = 'Item name';
  static const itemNameExample = 'e.g. Heirloom Tomatoes';
  static const categoryLabel = 'Category';
  static const selectOption = 'Select';
  static const skuLabel2 = 'SKU';
  static const skuHelper = 'Generated if left blank';
  static const skuExample = 'PRD-1001';
  static const descriptionLabel = 'Description';
  static const descriptionHelper = 'Shown on the item\'s detail page';
  static const descriptionExample = 'Grade, origin, prep notes…';
  static const trackStockLabel = 'Track stock for this item';
  static const trackStockOn = 'Counted against a low-stock threshold';
  static const trackStockOff = 'No counts, no low-stock warnings';
  static const moneyHint = '0.00';
  static const lowAlertLabel = 'Low stock alert';
  static const lowAlertHelper = 'Warn at or below this';
  static const reorderQtyLabel = 'Reorder quantity';
  static const reorderQtyHelper = 'How much to order when restocking';
  static const allowNegativeLabel = 'Allow stock to go negative';
  static const allowNegativeOn =
      'A sale can go through before the count catches up';
  static const allowNegativeOff =
      'A sale is blocked once stock reaches zero';
  static const priceRequiredTill = 'Required to appear on the POS menu';
  static const priceGroceryHint =
      'Not shown for groceries — change type to set a price';
  static const openingStock = 'Opening stock';
  static const openingStockHelper = 'What is on the shelf today';
  static const unitLabel = 'Unit';
  static const activeOption = 'Active';
  static const activeOptionBlurb = 'Counted and reorderable';
  static const archivedOption = 'Archived';
  static const archivedOptionBlurb = 'Kept for reporting only';
  static const currentStockReadonly = 'Current stock';
  static const adjustFlowHint = 'Changes go through Stock Adjust';
  static String stockValue(Object value, Object unit) => '$value $unit';
  static String itemSaved(String name, bool isEdit) =>
      isEdit ? '$name updated' : '$name added to inventory';

  // -------------------------------------------------------------------------
  // Reorder dialog
  // -------------------------------------------------------------------------

  static const selectSupplierFirst = 'Select a supplier';
  static String reorderCreated(String quantity, String unit, String name) =>
      'Reorder created: $quantity $unit of $name';
  static String createReorderFor(String name) => 'Create reorder for $name';
  static const reorderDetails = 'Reorder details';
  static const supplierPickLabel = 'Supplier';
  static const selectSupplierButton = 'Select supplier';
  static const changeSupplier = 'Change';
  static const quantityToOrder = 'Quantity to order';
  static const enterQuantity = 'Enter quantity';
  static const enterPositive = 'Enter a positive number';
  static const enterNonNegative = 'Enter a non-negative number';
  static const expectedDaysLabel = 'Expected delivery (days)';
  static const deliveryHint = '7';
  static const daysSuffix = 'days';
  static const wholeNumber = 'Enter a whole number';
  static const notesOptional = 'Notes (optional)';
  static const supplierNotesExample = 'Special requests or notes for supplier...';
  static const selectSupplierTitle = 'Select a supplier';
  static const searchSuppliers = 'Search suppliers';
  static const noMatchingSuppliers = 'No matching suppliers';
  static const addNewSupplier = 'Add new supplier';

  // -------------------------------------------------------------------------
  // Sales
  // -------------------------------------------------------------------------

  static const salesTitle = 'Sales';
  static String salesSubtitle(String date) =>
      'Orders, takings and refunds across $date';
  static const checkNewOrders = 'Check for new orders';
  static const totalSales = 'Total sales';
  static String netOfRefunds(String period) => 'Net of refunds, $period';
  static const selectedPeriod = 'the selected period';
  static const ordersMetric = 'Orders';
  static String itemsSold(int count) => '$count items sold';
  static const averageOrder = 'Average order';
  static const noRefundsInView = 'No refunds in this view';
  static String refundedCount(int count) => '$count refunded';
  static const searchOrders = 'Search order, server, item or payment';
  static const dateSort = 'Date';
  static const orderSort = 'Order';
  static const itemsSort = 'Items';
  static const totalSort = 'Total';
  static const paymentSort = 'Payment';
  static const fulfillmentSort = 'Fulfillment';
  static const statusSort = 'Status';
  static const viewDetailAction = 'View detail';
  static const assignCourier = 'Assign courier';
  static const refundOrder = 'Refund order';
  static const printReceipt = 'Print receipt';
  static String receiptSentWithNumber(String prefix, String suffix) =>
      'Receipt $prefix$suffix sent to printer';
  static String refundTitle(String id) => 'Refund $id?';
  static String refundBody(String total, String method) =>
      '$total will be returned to $method and removed from takings.';
  static String orderRefunded(String id) => '$id refunded';
  static const dateRangeFilter = 'Date range';
  static const paymentMethodFilter = 'Payment method';
  static const statusFilter = 'Status';
  static const selectSalesPeriod = 'Select a sales period';
  static const changePeriod = 'Change period';
  static const customPeriod = 'Custom…';
  static const customLabel = 'Custom';
  static String customRangeLabel(String from, String to) => '$from – $to';
  static const couriersTitle = 'Couriers';
  static const availableMetric = 'Available';
  static const readyForDelivery = 'Ready for delivery';
  static const unavailableMetric = 'Unavailable';
  static const offlineTrend = 'Offline';
  static const totalMetric = 'Total';
  static const couriersOnTeam = 'Couriers on team';
  static String activeCount(int count) => 'Active ($count)';
  static String inactiveCount(int count) => 'Inactive ($count)';
  static const noCouriers = 'No couriers added';
  static const recentBadge = 'NEW';
  static const orderColumn = 'Order';
  static const dateTimeColumn = 'Date & time';

  // -------------------------------------------------------------------------
  // Finance
  // -------------------------------------------------------------------------

  static const otherExpensesTitle = 'Other expenses';
  static const otherExpensesSubtitle =
      'Ad-hoc costs outside inventory purchases and payroll';
  static const addExpense = 'Add expense';
  static const totalExpenses = 'Total expenses';
  static const inCurrentView = 'In current view';
  static const entriesMetric = 'Entries';
  static const trackedInView = 'Tracked in view';
  static const largestCategory = 'Largest category';
  static const searchExpenses = 'Search description, payee or category';
  static const descriptionSort = 'Description';
  static const categorySort = 'Category';
  static const amountSort = 'Amount';
  static String deleteExpenseTitle(String name) => 'Delete $name?';
  static const deleteExpenseBody =
      'This expense will be removed and cannot be recovered.';
  static String expenseDeleted(String name) => '$name deleted';
  static const allEntries = 'All entries';
  static String financeExportBetween(
    String fromMonth,
    String fromDay,
    String toMonth,
    String toDay,
  ) =>
      'between $fromMonth/$fromDay and $toMonth/$toDay';
  static const otherIncomesTitle = 'Other incomes';
  static const otherIncomesSubtitle =
      'Ad-hoc revenue outside point-of-sale transactions';
  static const addIncome = 'Add income';
  static const totalOtherIncome = 'Total other income';
  static const averageEntry = 'Average entry';
  static const noEntries = 'No entries';
  static String entrySources(int count) => '$count sources';
  static const searchIncomes = 'Search description, source or category';
  static String deleteIncomeTitle(String name) => 'Delete $name?';
  static const deleteIncomeBody =
      'This income entry will be removed and cannot be recovered.';
  static String incomeDeleted(String name) => '$name deleted';
  static const categoryFilter = 'Category';
  static const pickDateRange = 'Pick a date range';
  static String financeFilterDate(
    String fromMonth,
    String fromDay,
    String toMonth,
    String toDay,
  ) =>
      '$fromMonth/$fromDay – $toMonth/$toDay';
  static const clearAllFilters = 'Clear all';
  static const financeExpensesTab = 'Other expenses';
  static const financeIncomesTab = 'Other incomes';
  static const addExpenseTitle = 'Add expense';
  static const editExpenseTitle = 'Edit expense';
  static const addIncomeTitle = 'Add income';
  static const editIncomeTitle = 'Edit income';
  static const dateLabel = 'Date';
  static const amountLabel = 'Amount';
  static const amountRequired = 'Amount is required';
  static const validAmount = 'Enter a valid amount';
  static const paymentMethodLabel = 'Payment Method';
  static const categoryRequired = 'Category is required';
  static const descriptionRequired = 'Description is required';
  static const payeeOptional = 'Payee (optional)';
  static const noteOptional = 'Note (optional)';
  static const sourceOptional = 'Source (optional)';
  static const receiptOptional = 'Receipt (optional)';
  static const uploadReceipt = 'Upload receipt';
  static const addAction = 'Add';
  static const updateAction = 'Update';
  static String expenseSaved(bool isEdit) =>
      isEdit ? 'Expense updated' : 'Expense added';
  static String incomeSaved(bool isEdit) =>
      isEdit ? 'Income updated' : 'Income added';
  static const refundWhyHint = 'Why is this being refunded?';
  static const refundAction = 'Refund';
  static String assignCourierTitle(String order) => 'Assign courier for $order';
  static const currentlyAssigned = 'Currently assigned';
  static const reassignTo = 'Reassign to';
  static const selectCourier = 'Select courier';
  static const noCouriersAvailable = 'No couriers available';
  static String courierAssigned(String name, String order) =>
      '$name assigned to $order';

  // -------------------------------------------------------------------------
  // Customers
  // -------------------------------------------------------------------------

  static const customersTitle = 'Customers';
  static const customersSubtitle = 'All customer profiles and order history';
  static const addCustomer = 'Add customer';
  static const totalCustomers = 'Total customers';
  static const registeredProfiles = 'Registered profiles';
  static const lifetimeSpend = 'Lifetime spend';
  static const totalRevenueFromCustomers = 'Total revenue from customers';
  static const averageSpend = 'Average spend';
  static const perCustomer = 'Per customer';
  static const searchCustomers = 'Search by name or phone';
  static const lastOrderSort = 'Last order';
  static const totalSpentSort = 'Total spent';
  static String deleteCustomerTitle(String name) => 'Delete $name?';
  static const deleteCustomerBody =
      'This customer record will be removed. This cannot be undone.';
  static String customerDeleted(String name) => '$name deleted';
  static const ordersColumn = 'Orders';
  static const lastOrderColumn = 'Last order';
  static const totalSpentColumn = 'Total spent';
  static const contactInfo = 'Contact info';
  static const fullNameExample = 'Amina Hassan';
  static const fullNameHint = 'Full name';
  static const enterNameError = 'Enter a name';
  static const phoneExample2 = '+1 (555) 123-4567';
  static const enterPhoneError = 'Enter a phone number';
  static const emailExample2 = 'email@example.com';
  static const addressExample2 = 'Street address (optional)';
  static const editCustomer = 'Edit customer';
  static const addCustomerTitle = 'Add customer';
  static String customerSaved(String name, bool isEdit) =>
      isEdit ? '$name updated' : '$name added';
  static const ordersPlaced = 'Orders placed';
  static const totalTransactions = 'Total transactions';
  static const totalSpentMetric = 'Total spent';
  static const lifetimeValue = 'Lifetime value';
  static const averageOrderMetric = 'Average order';
  static const perOrder = 'Per order';
  static const profilePanel = 'Profile';
  static const emailField = 'Email';
  static const addressField = 'Address';
  static const joinedField = 'Joined';
  static const lastOrderField = 'Last order';
  static const orderHistory = 'Order history';
  static String orderHistoryCount(int count) => '$count orders';
  static const noOrdersYet = 'No orders yet';
  static const customerNotFound = 'Customer not found';
  static String customerMissing(String id) => '$id doesn\'t exist';
  static const backToCustomers = 'Back to customers';

  // -------------------------------------------------------------------------
  // Staff
  // -------------------------------------------------------------------------

  static const staffTitle = 'Staff';
  static String staffSubtitle(int total, int roles, int active) =>
      '$total people across $roles roles · $active active';
  static const rolesAction = 'Roles';
  static const inviteStaff = 'Invite staff';
  static const totalStaff = 'Total staff';
  static String rolesInUse(int count) => '$count roles in use';
  static const activeMetric = 'Active';
  static const everyoneActive = 'Everyone active';
  static String deactivatedCount(int count) => '$count deactivated';
  static const pendingInvites = 'Pending invites';
  static const nothingOutstanding = 'Nothing outstanding';
  static const awaitingSignIn = 'Awaiting first sign-in';
  static const searchStaff = 'Search name, email or role';
  static const nameSort = 'Name';
  static const roleSort = 'Role';
  static const lastActiveSort = 'Last active';
  static const removeFromTeam = 'Remove from team';
  static String removeMemberTitle(String name) => 'Remove $name?';
  static String revokeRolesBody(int count) =>
      count == 1
          ? 'This revokes their role at this business.'
          : 'This revokes all $count of their roles at this business.';
  static const removeAction = 'Remove';
  static String memberRemoved(String name) => '$name removed from the team';
  static String removeRolesFailed(String name) =>
      "Couldn't remove all of $name's roles — try again";
  static const allStaffExport = 'All staff';
  static const nameCol = 'Name';
  static const roleCol = 'Role';
  static const emailCol = 'Email';
  static const lastActiveCol = 'Last active';
  static const statusCol = 'Status';
  static const neverActive = 'Never';
  static const recentActivity = 'Recent activity';
  static const addRole = 'Add role';
  static const contactPanel = 'Contact';
  static const invitedValue = 'Invited';
  static const joinedValue = 'Joined';
  static const lastActiveField = 'Last active';
  static const neverSignedIn = 'Never signed in';
  static const accessPanel = 'Access';
  static const noRolesHere = 'No roles at this business.';
  static const inviteMessage = 'Invite message';
  static String roleRemovedFrom(String role, String member) =>
      '$role removed from $member';
  static const couldNotRemoveRole = 'Could not remove that role';
  static const roleGone = 'This role no longer exists.';
  static const removeRoleTooltip = 'Remove this role';
  static const ordersToday = 'Orders today';
  static const notOnShift = 'Not on shift';
  static const onTheTill = 'On the till';
  static const ordersThisWeek = 'Orders this week';
  static const last7Days = 'Last 7 days';
  static const salesHandled = 'Sales handled';
  static const noInviteActivity =
      'Nothing yet — this invite has not been accepted';
  static const noActivityRecorded = 'No activity recorded';
  static String staffNotFound(String id) => 'Staff member $id not found';
  static const backToStaff = 'Back to staff';

  // -------------------------------------------------------------------------
  // Notifications
  // -------------------------------------------------------------------------

  static const notificationsTitle = 'Notifications';
  static const markAllRead = 'Mark all read';
  static const noNotificationsYet = 'No notifications yet';
  static const notificationsEmptyHint =
      'Orders, low stock alerts and insights will appear here';
  static const markAsRead = 'Mark as read';
  static const newOrderType = 'New Order';
  static const lowStockType = 'Low Stock';
  static const aiInsightType = 'AI Insight';
  static const deliveryUpdateType = 'Delivery Update';

  // -------------------------------------------------------------------------
  // Enum display labels (badges, dropdowns, timelines)
  // -------------------------------------------------------------------------

  static const cashLabel = 'Cash';
  static const cardLabel = 'Card';
  static const qrisLabel = 'QRIS';
  static const mobilePayLabel = 'Mobile Pay';
  static const giftCardLabel = 'Gift Card';
  static const paidStatus = 'Paid';
  static const refundedStatus = 'Refunded';
  static const voidedStatus = 'Voided';
  static const pendingStatus = 'Pending';
  static const newStatus = 'New';
  static const preparingStatus = 'Preparing';
  static const readyStatus = 'Ready';
  static const outForDeliveryStatus = 'Out for Delivery';
  static const completedStatus = 'Completed';
  static const dineInType = 'Dine-in';
  static const takeawayType = 'Takeaway';
  static const deliveryType = 'Delivery';
  static const inStockStatus = 'In stock';
  static const lowStockStatus = 'Low stock';
  static const outOfStockStatus = 'Out of stock';
  static const activeStatus = 'Active';
  static const inactiveStatus = 'Inactive';
  static const pendingInviteStatus = 'Pending invite';
  static const courierAvailable = 'Available for deliveries';
  static const courierUnavailable = 'Not available';
  static const reorderPending = 'Pending';
  static const reorderPendingBlurb = 'Awaiting delivery';
  static const reorderReceived = 'Received';
  static const reorderReceivedBlurb = 'Stock added';
  static const reorderCancelled = 'Cancelled';
  static const reorderCancelledBlurb = 'Order cancelled';
  static const headOfficeType = 'Head Office';
  static const restaurantBranchType = 'Restaurant Branch';
  static const kitchenType = 'Kitchen';
  static const warehouseType = 'Warehouse';
  static const farmType = 'Farm';
  static const depotType = 'Depot';
  static const todayRange = 'Today';
  static const weekRange = 'This week';
  static const monthRange = 'This month';
  static const allTimeRange = 'All time';
  static const customRange = 'Custom';
  static const restockMovement = 'Restock';
  static const saleMovement = 'Sale';
  static const wasteMovement = 'Waste';
  static const adjustmentMovement = 'Adjustment';
  static const transferMovement = 'Transfer';
  static const restaurantType = 'Restaurant';
  static const supplierType = 'Supplier';
  static const farmerType = 'Farmer';
  static const distributorType = 'Distributor';
  static const platformOperatorType = 'Platform Operator';
  static const otherType = 'Other';
  static const comfortableDensity = 'Comfortable';
  static const comfortableBlurb = 'Roomier rows, easier to tap';
  static const compactDensity = 'Compact';
  static const compactBlurb = 'More rows on screen at once';
  static const englishLanguage = 'English';

  // -------------------------------------------------------------------------
  // Order detail
  // -------------------------------------------------------------------------

  static const orderTypeLabel = 'Order type';
  static const seatedAt = 'Seated at';
  static const serverLabel = 'Server';
  static const placedLabel = 'Placed';
  static const detailsPanel = 'Details';
  static String itemCountTitle(int count) => '$count items';
  static String quantityPrice(String quantity, String price) =>
      '$quantity × $price';
  static const paymentPanel = 'Payment';
  static const subtotalRow = 'Subtotal';
  static String discountRow(String percent) => 'Discount ($percent)';
  static String discountAmount(String amount) => '−$amount';
  static String taxRow(String percent) => 'Tax ($percent)';
  static const totalRow = 'Total';
  static String refundedTo(String method) => 'Refunded to $method';
  static String paidBy(String method) => 'Paid by $method';
  static String receiptSent(String id) => 'Receipt for $id sent to printer';
  static const changeCourier = 'Change courier';
  static const assignCourierAction = 'Assign courier';
  static const alreadyRefunded = 'Already refunded';
  static const refundOrderAction = 'Refund order';
  static String statusChanged(String label) => 'Status changed to $label';
  static String refundDialogTitle(String id) => 'Refund $id?';
  static String refundDialogBody(String total, String method) =>
      '$total will be returned to $method and removed from today\'s takings.';
  static String orderRefunded2(String id) => '$id refunded';
  static String orderNotFound(String id) => 'Order $id not found';
  static const backToSales = 'Back to sales';

  // -------------------------------------------------------------------------
  // AI insights
  // -------------------------------------------------------------------------

  static const insightsTitle = 'Insights';
  static const insightsSubtitle =
      'Generated from your live stock, sales and waste data';
  static const askNotConnected =
      'Ask is not connected to a model yet — the cards on the left are '
      'generated locally from your data.';
  static const askAboutBusiness = 'Ask about your business';
  static const askExample = 'e.g. which supplier costs me the most?';
  static const askAction = 'Ask';
  static const tryAsking = 'TRY ASKING';

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  static const goodMorning = 'Good morning';
  static const goodAfternoon = 'Good afternoon';
  static const goodEvening = 'Good evening';
  static String greetingFor(String greeting, String firstName) =>
      '$greeting, $firstName';
  static const openTill = 'Open till';
  static const todaySales = "Today's sales";
  static String vsYesterday(String amount) => 'vs $amount yesterday';
  static String yesterdayCount(String count) => '$count yesterday';
  static const avgOrderValue = 'Avg order value';
  static const perTicket = 'per ticket';
  static const staffOnShift = 'Staff on shift';
  static String ofActive(String total) => 'of $total active';
  static const netProfitToday = 'Net profit today';
  static const revenueCard = 'Revenue';
  static const last7DaysLabel = 'Last 7 days';
  static const salesByCategory = 'Sales by category';
  static const topSellingItems = 'Top selling items';
  static const recentActivityCard = 'Recent activity';
  static const noSales7Days = 'No sales in the last 7 days.';
  static String unitsSold(Object units) => '$units sold';
  static String dateSuffix(String date) => ' · $date';
  static String orderPaid(String id) => 'Order $id paid';
  static String orderRefundedFeed(String id) => 'Order $id refunded';
  static String orderFeedDetail(int items, String server, String method) =>
      '$items items · $server · $method';
  static String stockOutFeed(String name) => '$name is out of stock';
  static String stockLowFeed(String name) => '$name is running low';
  static String stockRemaining(
    Object stock,
    Object level,
    String unit,
  ) =>
      '$stock of $level $unit remaining';

  // -------------------------------------------------------------------------
  // Dashboard widgets
  // -------------------------------------------------------------------------

  static const lookAtToday = 'What to look at today';
  static const seeAll = 'See all';
  static const noSalesThisPeriod = 'No sales in this period';
  static const noSalesBreakdown = 'No sales to break down yet';
  static const totalFallback = 'Total';
  static String sharePercent(double share) => '${(share * 100).round()}%';
  static String stockAlertHeadline(int out, int low) =>
      '$out out of stock, $low running low';
  static String reorderNeeded(int count) =>
      '$count ${count == 1 ? 'line needs' : 'lines need'} reordering';
  static String namesAndMore(String names, int extra) =>
      '$names and $extra more';
  static String rankBadge(int rank) => '$rank';
  static String trendPercent(double percent) =>
      '${percent < 10 ? percent.toStringAsFixed(1) : percent.round()}%';
  static String roleSaved(String name, bool isEdit) =>
      isEdit ? '"$name" updated' : '"$name" created';
  static const roleSaveFailed = 'Something went wrong saving this role.';
  static const editRole = 'Edit role';
  static const createRole = 'Create role';
  static const saveRole = 'Save role';
  static const basicInfoSection = 'Basic info';
  static const roleNameLabel = 'Role name';
  static const roleNameExample = 'e.g. Shift supervisor';
  static const nameRequired = 'Give the role a name';
  static const descriptionLabel2 = 'Description';
  static const roleDescriptionHelper = 'One line on what this role is for';
  static const roleDescriptionExample = 'Runs the floor when a manager is off';
  static const pickPermissionWarning =
      'Pick at least one permission — a role that grants nothing cannot '
      'be assigned usefully.';
  static const builtinNameLocked =
      'Built-in roles keep their name and description. You can still change '
      'what this role is allowed to do.';
  static const permissionsSection = 'Permissions';
  static String permissionsSelected(int on, int total) =>
      '$on of $total selected';
  static const selectAll = 'Select all';
  static String groupSelected(int on, int total) => '$on of $total';
  static const clearGroup = 'Clear';
  static const allGroup = 'All';
  static const roleFilter = 'Role';
  static String inviteSentTo(String name) => 'Invite sent to $name';
  static const staffNeedsInternet =
      'Staff management requires an internet connection.';
  static const inviteFailed = 'Something went wrong sending the invite.';
  static const inviteStaffTitle = 'Invite staff';
  static const sendInvite = 'Send invite';
  static const fullNameLabel = 'Full name';
  static const teammateExample = 'e.g. Tomas Alvarez';
  static const invitePhoneHelper =
      "Their invite is sent to this number — it's how the backend finds "
      'or creates their account';
  static const addRoleTitle = 'Add a role';
  static const roleFallbackName = 'the role';
  static const addRoleButton = 'Add role';
  static const holdsAllRoles =
      'They already hold every role at this business.';
  static String memberHasRole(String member, String role) =>
      '$member now has $role';
  static const addRoleFailed = 'Something went wrong adding the role.';
  static const roleLabel2 = 'Role';
  static const selectRoleHint = 'Select a role';
  static const pickRole = 'Pick a role';
  static const roleWithoutPermissions =
      'This role grants no permissions yet.';
  static String extraRoles(int count) => '+$count more';
  static const enterFullName = 'Enter their full name';
  static const rolesPermissionsTitle = 'Roles & permissions';
  static String rolesSubtitle(int roles, int assigned) =>
      '$roles roles · $assigned staff assigned';
  static const backToStaffButton = 'Back to staff';
  static const createRoleButton = 'Create role';
  static const totalRoles = 'Total roles';
  static String builtInCount(int count) => '$count built in';
  static const customRoles = 'Custom roles';
  static const noneCreatedYet = 'None created yet';
  static const createdForBusiness = 'Created for this business';
  static const staffAssigned = 'Staff assigned';
  static const acrossAllRoles = 'Across all roles';
  static const editRoleAction = 'Edit role';
  static const duplicateAction = 'Duplicate';
  static const deleteRoleAction = 'Delete';
  static String roleDuplicated(String name) => 'Created "$name"';
  static String deleteRoleTitle(String name) => 'Delete "$name"?';
  static const deleteRoleBody =
      'This role is not assigned to anyone and will be removed permanently.';
  static String roleDeleted(String name) => '"$name" deleted';
  static const builtinCaption =
      'Built-in roles can be edited but not renamed or deleted.';
  static const roleColumn = 'Role';
  static const staffColumn = 'Staff';
  static const permissionsColumn = 'Permissions';
  static const typeColumn2 = 'Type';
  static const builtInBadge = 'Built in';
  static const customBadge = 'Custom';
  static const builtinLockedTooltip =
      'Built-in roles cannot be renamed or deleted';

  // -------------------------------------------------------------------------
  // Settings hub
  // -------------------------------------------------------------------------

  static const businessProfileEntry = 'Business profile';
  static const businessProfileBlurb =
      'Name, logo, brand colour and contact details';
  static const loadingEllipsis = 'Loading...';
  static const storeSettingsEntry = 'Store settings';
  static const storeSettingsBlurb =
      'Tax, currency, receipts and trading hours';
  static const taxInclusive = 'inclusive';
  static const taxOnTop = 'on top';
  static const storeLocationsEntry = 'Store locations';
  static const storeLocationsBlurb = 'Sites this business trades from';
  static String locationCount(int total) => '$total locations';
  static String locationsActive(int active, int total) =>
      '$active of $total active';
  static const staffRolesEntry = 'Staff & roles';
  static const staffRolesBlurb = 'Who works here and what they can do';
  static String staffRolesValue(int staff, int roles) =>
      '$staff staff · $roles roles';
  static const accountEntry = 'Account';
  static const accountBlurb = 'Your own profile, PIN and sign-in security';
  static const notSignedIn = 'Not signed in';
  static const appPrefsEntry = 'App preferences';
  static const appPrefsBlurb =
      'Theme, notifications and table density on this device';
  static const themeSystem = 'System';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const devicesEntry = 'Devices & printers';
  static const devicesBlurb = 'Terminals, receipt printers and cash drawers';
  static const notConfigured = 'Not configured';
  static const settingsTitle = 'Settings';
  static const settingsSubtitle =
      'How this business and this terminal are configured';
  static const comingSoon = 'Coming soon';

  // -------------------------------------------------------------------------
  // Store settings
  // -------------------------------------------------------------------------

  static const storeSettingsSaved = 'Store settings saved';
  static const storeSettingsTitle = 'Store settings';
  static const storeSettingsSubtitle =
      'Tax, receipts and trading hours for this store';
  static const saveChangesAction = 'Save changes';
  static const taxPricingPanel = 'Tax & pricing';
  static const taxRateField = 'Tax rate';
  static const newTicketHelper = 'Applied to every new ticket';
  static const percentRangeError = 'Must be between 0 and 100';
  static const serviceChargeField = 'Service charge';
  static const serviceChargeHelper = 'Leave at 0 if not applied';
  static const pricesIncludeTax = 'Prices include tax';
  static const taxInclusivePrices =
      'Menu prices are tax-inclusive; receipts show the tax within';
  static const taxAddedAtCheckout = 'Tax is added to the subtotal at checkout';
  static const currencyField = 'Currency';
  static const currencyShownHelper = 'Formats every amount shown in the app';
  static String currencyPreview(String sample) =>
      'Prices will read as $sample';
  static const orderReceiptPanel = 'Order & receipt';
  static const defaultOrderTypeField = 'Default order type';
  static const preselectedPosHelper = 'Pre-selected on the POS panel';
  static const receiptPrefixField = 'Receipt number prefix';
  static const receiptPrefixExample = 'e.g. INV-1042';
  static const receiptPrefixHint = 'INV-';
  static const receiptPrefixLengthError = 'Keep it under 8 characters';
  static const receiptPrefixLength = 'Keep it under 8 characters';
  static const autoPrintReceipt = 'Auto-print receipt';
  static const autoPrintOn =
      'A receipt prints as soon as payment settles';
  static const autoPrintOff = 'Receipts print only when asked for';
  static const operatingHours = 'Operating hours';
  static const opensAt = 'Opens at';
  static const closesAt = 'Closes at';
  static const openValue = 'Open';
  static const closedValue = 'Closed';
  static const closesNextMorning = 'Closes the next morning';
  static const openEveryDay = 'Open every day';
  static const closedAllWeek = 'Closed all week';
  static String closedDays(String days) => 'Closed $days';
  static const weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const weekdayShortNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // -------------------------------------------------------------------------
  // Business profile
  // -------------------------------------------------------------------------

  static const noProfileLoaded = 'No business profile loaded';
  static const businessProfileSaved = 'Business profile saved';
  static String profileSaveFailed(Object e) => 'Error saving profile: $e';
  static const businessProfileTitle = 'Business profile';
  static const businessProfileSubtitle =
      'Identity and contact details synced with backend';
  static const savingEllipsis = 'Saving...';
  static const brandingPanel = 'Branding';
  static const addLogoAction = 'Add logo';
  static const logoPreviewHint = 'Preview only — not yet saved';
  static const logoReceiptHint = 'Square PNG or JPG reads best on a receipt';
  static const accentColour = 'Accent colour';
  static const businessDetails = 'Business details';
  static const businessNameField = 'Business name';
  static const businessNameHelper = 'Displayed in the app and on receipts';
  static const businessNameHint2 = 'My Restaurant';
  static const businessNameRequired = 'Business name is required';
  static const businessTypeField = 'Business type';
  static const cuisineField = 'Cuisine type';
  static const optionalField = 'Optional';
  static const cuisineExample2 = 'e.g., Italian, Thai';
  static const registrationPanel = 'Registration & compliance';
  static const taxIdField = 'Tax ID';
  static const taxIdHelper2 = 'VAT/GST number';
  static const registrationField = 'Registration number';
  static const registrationHelper = 'Business license / registration ID';
  static const licenseDocField = 'License / registration document';
  static const licenseDocHelper2 =
      "Optional — paste a link to where it's hosted";
  static const contactPanel2 = 'Contact information';
  static const emailField2 = 'Email';
  static const emailHelper2 = 'Business contact email';
  static const emailHint2 = 'contact@business.com';
  static const phoneField2 = 'Phone';
  static const phoneHelper2 = 'Contact number';
  static const phoneHint2 = '+255 ...';
  static const addressField2 = 'Address';
  static const addressHelper2 = 'Physical business address';
  static const addressHint2 = 'Street address';
  static const cityField = 'City';
  static const cityHelper = 'City or locality';
  static const cityExample = 'e.g., Dar es Salaam';

  // -------------------------------------------------------------------------
  // Account
  // -------------------------------------------------------------------------

  static const accountTitle = 'Account';
  static const accountSubtitle = 'Your own details and how you sign in';
  static const profilePanel2 = 'Profile';
  static const photoUploadLabel = 'Photo';

  // -------------------------------------------------------------------------
  // Locations
  // -------------------------------------------------------------------------

  static String locationSaved(String name, bool isEdit) => isEdit
      ? '$name updated'
      : '$name added — it can now receive stock transfers';
  static const locationSaveFallback = 'Could not save location';
  static String locationSaveFailed(Object e) => 'Error saving location: $e';
  static const editLocation = 'Edit location';
  static const addLocationTitle = 'Add location';
  static const saveLocation = 'Save location';
  static const locationNameField = 'Location name';
  static const locationNameExample = 'Harbour Point';
  static const locationNameRequired = 'Give the location a name';
  static const locationNameTaken = 'That name is already used';
  static const locationTypeField = 'Location type';
  static const addressField3 = 'Address';
  static const addressExample3 = '12 Pier Road, San Francisco';
  static const phoneField4 = 'Phone';
  static const phoneExample4 = '+1 415 555 0142';
  static const staffBasedHere = 'Staff based here';
  static const staffCountHint = '0';
  static const managerField = 'Manager';
  static const managerHelper = 'Anyone on the staff list can run a site';
  static const activeSwitch = 'Active';
  static const currentTerminalTrades =
      'This terminal is installed here, so it always trades';
  static const tradingTransferDest =
      'Trading, and offered as a stock transfer destination';
  static const keptForHistory = 'Kept for history; offered nowhere';
  static const oneActiveRequired = 'At least one location has to stay active';
  static String managerPending(String name) => '$name (invite pending)';
  static const unassignedManager = 'Unassigned';
  static const storeLocationsTitle = 'Store locations';
  static const storeLocationsSubtitle =
      'Sites this business trades from and moves stock between';
  static const backToSettings = 'Back to settings';
  static const addLocationAction = 'Add location';
  static const totalLocations = 'Total locations';
  static const singleSite = 'Single site';
  static const acrossBusiness = 'Across the business';
  static const activeLocations = 'Active locations';
  static const allTrading = 'All trading';
  static String inactiveLocations(int count) => '$count inactive';
  static const totalStaffMetric = 'Total staff';
  static const basedAllSites = 'Based across all sites';
  static const editLocationAction = 'Edit location';
  static const toggleActiveAction = 'Activate / deactivate';
  static String locationToggled(String name, bool wasActive) =>
      '$name ${wasActive ? 'deactivated' : 'reactivated'}';
  static const deleteLocationAction = 'Delete';
  static String deleteLocationTitle(String name) => 'Delete "$name"?';
  static const deleteLocationEmpty =
      'Stock movements recorded against this site keep their history, '
      'but it will no longer be offered as a transfer destination.';
  static String deleteLocationStaffed(int count) =>
      '$count people are based here. They will keep their records, but '
      'the site will no longer be offered as a transfer destination.';
  static String locationDeleted(String name) => '"$name" deleted';

  // -------------------------------------------------------------------------
  // Store Details
  // -------------------------------------------------------------------------

  static const storeDetailsTitle = 'Store Details';
  static const storeDetailsSaved = 'Store settings saved';
  static const failedToSaveSettings = 'Failed to save settings';
  static const storeLocationSection = 'Location';
  static const latitudeLabel = 'Latitude';
  static const longitudeLabel = 'Longitude';
  static const storeContactSection = 'Contact';
  static const storeEmailLabel = 'Email';
  static const storePhoneLabel = 'Phone';
  static const storeSalesChannelsSection = 'Sales Channels';
  static const storePricingSection = 'Pricing';
  static const storeCurrencyLabel = 'Currency';
  static const tzShilling = 'TZS - Tanzanian Shilling';
  static const usDollar = 'USD - US Dollar';
  static const euroLabel = 'EUR - Euro';
  static const storeCreditTabsSection = 'Credit & Tabs';
  static const creditLimitLabel = 'Credit limit';
  static const maxPaymentTimeLabel = 'Max payment time (min)';
  static const storeOperationalSection = 'Operational';
  static const storeLogoSection = 'Logo';
  static const logoUrlLabel = 'Logo URL';
  static const storeHoursReceiptsSection = 'Hours & Receipts';
  static const hoursOfOperation = 'Hours of Operation';
  static const receiptSettings = 'Receipt Settings';
  static const addStaffComingSoon = 'Add staff coming soon';
  static const lastActiveNoDelete =
      'The last active location cannot be deleted';
  static const lastActiveLocked =
      'The last active location cannot be deactivated or deleted.';
  static String terminalHereLocked(String name) =>
      'This terminal is installed at $name. The last active location '
      'cannot be deactivated or deleted.';
  static const locationColumn = 'Location';
  static const addressColumn = 'Address';
  static const managerColumn = 'Manager';
  static const locationStaffColumn = 'Staff';
  static const activeValue = 'Active';
  static const inactiveValue = 'Inactive';
  static const thisStoreMarker = 'This store';

  // -------------------------------------------------------------------------
  // App preferences
  // -------------------------------------------------------------------------

  static const appPreferencesTitle = 'App preferences';
  static const appPreferencesSubtitle =
      'How this app looks and behaves on this device';
  static const appearancePanel = 'Appearance';
  static const followingDeviceTheme =
      "Following this device's light/dark setting";
  static const alwaysLight = 'Always light, whatever the device is set to';
  static const alwaysDark = 'Always dark, whatever the device is set to';
  static const notificationsPanel = 'Notifications';
  static const lowStockAlerts = 'Low stock alerts';
  static const lowStockAlertsHelper =
      'Warn when a line drops below its reorder level';
  static const newOrderSounds = 'New order sounds';
  static const newOrderSoundsHelper = 'Chime when a ticket lands at this terminal';
  static const dailySummaryEmail = 'Daily summary email';
  static const dailySummaryHelper = "Yesterday's takings, sent each morning";
  static const displayPanel = 'Display';
  static const tableDensityLabel = 'Table density';
  static const languageField = 'Language';
  static const moreLanguages = 'More languages are on the way';
  static const accountPanel2 = 'Account';
  static const logOut = 'Log out';
  static const logOutTitle = 'Log out?';
  static const logOutGeneric =
      'You will need to sign in again to use this terminal.';
  static String logOutNamed(String name) =>
      '$name will be signed out of this terminal. Any open ticket '
      'stays on the till.';
  static const staySignedIn = 'Stay signed in';
  static const signOutPending = 'Sign-out takes effect once accounts are connected';
  static const fullNameField = 'Full name';
  static const emailField3 = 'Email';
  static const phoneField3 = 'Phone';
  static const profilePhotoSheet = 'Profile photo';
  static const choosePhoto = 'Choose a photo';
  static const securityPanel = 'Security';
  static const unlockPin = 'Unlock PIN';
  static const pinSetHint = 'Six digits, used to unlock this terminal';
  static const noPinYet = 'No PIN set yet';
  static const changePin = 'Change PIN';
  static const setPinAction = 'Set PIN';
  static const twoFactorOtp = 'Two-factor via OTP';
  static const twoFactorOn =
      'A code is texted to you on top of your PIN';
  static const twoFactorOff = 'Your PIN alone unlocks this terminal';
  static const dangerZone = 'DANGER ZONE';
  static const deactivateExplainer =
      'Deactivating closes your own access to this business. It is not '
      'the same as an owner deactivating someone else from the Staff '
      'screen — only you can do this to your own account, and you will '
      'need an owner to let you back in.';
  static const deactivateAccount = 'Deactivate my account';
  static const deactivateTitle = 'Deactivate your account?';
  static String deactivateBody(String name) =>
      '$name will lose access to this business immediately and be signed '
      'out of every terminal. Sales already recorded stay on the ledger. '
      'Only an owner can reactivate the account.';
  static const yourAccountFallback = 'your account';
  static const keepMyAccount = 'Keep my account';
  static const deactivateConfirm = 'Deactivate';

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  static const reportsTitle = 'Reports';
  static const dateColumn = 'Date';
  static const revenueColumn = 'Revenue';
  static const avgTicketColumn = 'Avg ticket';
  static const revenueMetric = 'Revenue';
  static String ordersTrend(int count) => '$count orders';
  static const avgTicketMetric = 'Avg ticket';
  static const perOrderTrend = 'Per order';
  static const dailyTakingsSection = 'Daily takings';
  static const noSalesInWindow = 'No sales in this window';
  static String takingsRow(String money, int orders) =>
      '$money · $orders orders';
  static const qtyColumn = 'Qty';
  static const itemMixSection = 'Item mix';
  static const nothingSold = 'Nothing sold in this window';
  static String itemMixRow(String quantity, String money) =>
      '$quantity · $money';
  static const salesColumn = 'Sales';
  static const voidRefundColumn = 'Void/refund';
  static const staffPerformanceSection = 'Staff performance';
  static const noStaffSales = 'No staff sales in this window';
  static String staffRow(int sales, String money) => '$sales sales · $money';
  static const netMetric = 'Net';
  static const netTrend = 'Sales + income − expenses';
  static const expensesMetric = 'Expenses';
  static const adhocSpend = 'Ad-hoc spend';
  static const spendByCategory = 'Spend by category';
  static const noExpenses = 'No expenses in this window';
  static const wastedColumn = 'Wasted';
  static const costColumn = 'Cost';
  static const wasteSection = 'Waste';
  static const noWaste = 'No waste recorded in this window';
  static String costWasted(String money) => 'Cost wasted: $money';
  static String wasteRow(String quantity, String unit, String money) =>
      '$quantity $unit · $money';
  static String consumedRow(String quantity, String unit) =>
      '$quantity $unit';
  static String overPortionedValue(double over, String formatted) =>
      '${over > 0 ? '+' : ''}$formatted';
  static const ingredientColumn = 'Ingredient';
  static const consumedColumn = 'Consumed';
  static const productionRunsTrend = 'Production runs';
  static const overPortioned = 'Over-portioned';
  static const actualVsSuggested = 'Actual vs suggested';
  static const ingredientsConsumed = 'Ingredients consumed';
  static const noProduction = 'No production in this window';
  static const linesColumn = 'Lines';
  static const valueColumn = 'Value';
  static const uncategorized = 'Uncategorized';
  static const inventoryValueMetric = 'Inventory value';
  static const onHandAtCost = 'On hand at cost, right now';
  static const valueByCategory = 'Value by category';
  static const inventoryValuation = 'Inventory valuation';
  static const nothingOnHand = 'Nothing on hand';
  static String valuationRow(int lines, String money) =>
      '$lines lines · $money';

  // -------------------------------------------------------------------------
  // Validators
  // -------------------------------------------------------------------------

  static const tanzanianPhoneError =
      'Enter a valid Tanzanian phone number (6 or 7XXXXXXXX)';
  static const giveItemName = 'Give the item a name';
  static const pickCategory = 'Pick a category';
  static const enterUnitCost = 'Enter a unit cost';
  static const enterNumberError = 'Enter a number';
  static const negativeCost = 'Cost cannot be negative';
  static const negativeNumber = 'Cannot be negative';
  static const sellingPriceRequired =
      'Enter a selling price to sell this at the till';
  static const describeExpense = 'Describe the expense';
  static const describeIncome = 'Describe the income';
  static const enterAmount = 'Enter an amount';
  static const amountPositiveError = 'Amount must be greater than zero';
}
