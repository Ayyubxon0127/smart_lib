import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

class S {
  final String lang;
  const S._(this.lang);

  static S of(BuildContext context) {
    final lang = context.watch<AppProvider>().lang;
    return S._(lang);
  }

  static S read(BuildContext context) {
    final lang = context.read<AppProvider>().lang;
    return S._(lang);
  }

  // Navigation
  String get navHome => _t('Bosh', 'Home', 'Главная');
  String get navBooks => _t('Kitoblar', 'Books', 'Книги');
  String get navMine => _t('Mening', 'Mine', 'Мои');
  String get navNews => _t("E'lonlar", 'Announcements', 'Объявления');
  String get navSettings => _t('Sozlamalar', 'Settings', 'Настройки');

  // App general
  String get appTitle => _t('Smart Kutubxona', 'Smart Library', 'Умная Библиотека');
  String get uniSystem => _t('Universitet Kutubxona Tizimi', 'University Library System', 'Университетская Система');

  // Home screen
  String greeting(String name) => _t('Salom, $name!', 'Hello, $name!', 'Привет, $name!');
  String get library => _t('Kutubxona', 'Library', 'Библиотека');
  String get student => _t('Talaba', 'Student', 'Студент');
  String get librarian => _t('Kutubxonachi', 'Librarian', 'Библиотекарь');
  String get activeReservations => _t('Faol bronlar', 'Active reservations', 'Активные брони');
  String get booksRead => _t("O'qilgan kitoblar", 'Books read', 'Прочитано книг');
  String get overdueWarning => _t("Muddati o'tgan kitob(lar) mavjud!", 'Overdue books!', 'Есть просроченные книги!');
  String get newBooks => _t('Yangi kitoblar', 'New books', 'Новые книги');
  String get loadingBooks => _t('Kitoblar yuklanmoqda...', 'Loading books...', 'Загрузка книг...');
  String get recentAnnouncements => _t("So'nggi e'lonlar", 'Recent announcements', 'Последние объявления');
  String get noAnnouncements => _t("E'lonlar yo'q", 'No announcements', 'Нет объявлений');

  // Books screen
  String get books => _t('Kitoblar', 'Books', 'Книги');
  String get searchHint => _t('Kitob yoki muallif qidirish...', 'Search book or author...', 'Поиск книги или автора...');
  String get all => _t('Barchasi', 'All', 'Все');
  String get bookNotFound => _t('Kitob topilmadi', 'Book not found', 'Книга не найдена');
  String available(int n) => _t('$n bo\'sh', '$n available', '$n свободно');
  String get reserve => _t('Bron', 'Reserve', 'Бронь');
  String get busy => _t('Band', 'Busy', 'Занято');
  String get reserveBook => _t('Bron qilish', 'Reserve book', 'Забронировать');
  String get notAvailable => _t('Mavjud emas', 'Not available', 'Недоступно');
  String get reserveSuccess => _t('Bron qilindi! Kutubxonachi tasdiqlashini kuting.', 'Reserved! Wait for librarian confirmation.', 'Забронировано! Ждите подтверждения библиотекаря.');
  String get reserveSuccessFull => _t('✅ Bron qilindi! Kutubxonachi tasdiqlashini kuting.', '✅ Reserved! Wait for librarian confirmation.', '✅ Забронировано! Ждите подтверждения.');

  // My books screen
  String get myBooks => _t('Mening kitoblarim', 'My books', 'Мои книги');
  String get noReservations => _t("Hali bron qilingan kitob yo'q", 'No reserved books yet', 'Нет забронированных книг');
  String get book => _t('Kitob', 'Book', 'Книга');
  String get statusPendingConfirm => _t('Tasdiq kutilmoqda', 'Awaiting confirmation', 'Ожидает подтверждения');
  String get statusActive => _t('Faol', 'Active', 'Активно');
  String get statusReturnRequested => _t("Qaytarish so'rovi", 'Return requested', 'Запрос на возврат');
  String get statusReturned => _t('Qaytarilgan', 'Returned', 'Возвращено');
  String get statusUnknown => _t("Noma'lum", 'Unknown', 'Неизвестно');
  String daysOverdue(int n) => _t('$n kun kechikdi', '$n days overdue', '$n дн. просрочено');
  String daysLeft(int n) => _t('$n kun qoldi', '$n days left', '$n дн. осталось');
  String get returnRequest => _t("Qaytarish so'rovi", 'Return request', 'Запрос на возврат');
  String get returnRequestSent => _t("Qaytarish so'rovi yuborildi", 'Return request sent', 'Запрос на возврат отправлен');

  // News screen
  String get announcements => _t("E'lonlar", 'Announcements', 'Объявления');
  String get noAnnouncementsYet => _t("Hali e'lon yo'q", 'No announcements yet', 'Объявлений пока нет');
  String get typeNewBooks => _t('Yangi kitob', 'New book', 'Новая книга');
  String get typeInfo => _t("Ma'lumot", 'Info', 'Информация');
  String get typeReminder => _t('Eslatma', 'Reminder', 'Напоминание');
  String get typeSurvey => _t("So'rovnoma", 'Survey', 'Опрос');
  String get important => _t('⚠️ Muhim', '⚠️ Important', '⚠️ Важно');

  // Settings screen
  String get settings => _t('Sozlamalar', 'Settings', 'Настройки');
  String get appearance => _t("Ko'rinish", 'Appearance', 'Внешний вид');
  String get darkMode => _t("Qorong'u rejim", 'Dark mode', 'Тёмный режим');
  String get lightMode => _t("Yorug' rejim", 'Light mode', 'Светлый режим');
  String get language => _t('Til', 'Language', 'Язык');
  String get support => _t("Qo'llab-quvvatlash", 'Support', 'Поддержка');
  String get write => _t('Yozish', 'Write', 'Написать');
  String get editProfile => _t('Profilni tahrirlash', 'Edit profile', 'Редактировать профиль');
  String get save => _t('Saqlash', 'Save', 'Сохранить');
  String get logout => _t('Akkauntdan chiqish', 'Sign out', 'Выйти из аккаунта');
  String get educationLevel => _t("Ta'lim darajasi", 'Education level', 'Уровень образования');
  String get direction => _t("Yo'nalish", 'Direction', 'Направление');
  String get faculty => _t('Fakultet', 'Faculty', 'Факультет');
  String get aboutYourself => _t("O'zingiz haqingizda...", 'About yourself...', 'О себе...');
  String get fullName => _t("To'liq ism *", 'Full name *', 'Полное имя *');
  String get phone => _t('Telefon', 'Phone', 'Телефон');
  String get group => _t('Guruh (CS-21)', 'Group (CS-21)', 'Группа (CS-21)');
  String get editProfileTitle => _t('Profilni tahrirlash', 'Edit profile', 'Редактировать профиль');
  String get masterDirection => _t("Magistratura yo'nalishi", 'Master direction', 'Направление магистратуры');
  String get bakalavr => _t('🎓 Bakalavr', '🎓 Bachelor', '🎓 Бакалавр');
  String get magistr => _t('🏅 Magistr', '🏅 Master', '🏅 Магистр');

  // Login screen
  String get signIn => _t('Kirish', 'Sign in', 'Войти');
  String get password => _t('Parol', 'Password', 'Пароль');
  String get noAccount => _t("Hisobingiz yo'qmi? ", "Don't have an account? ", 'Нет аккаунта? ');
  String get registerLink => _t("Ro'yhatdan o'tish", 'Register', 'Зарегистрироваться');
  String get errorOccurred    => _t('Xatolik yuz berdi', 'An error occurred', 'Произошла ошибка');
  String get wrongCredentials => _t('Email yoki parol noto\'g\'ri', 'Incorrect email or password', 'Неверный email или пароль');
  String get invalidEmail     => _t('Email noto\'g\'ri formatda', 'Invalid email format', 'Неверный формат email');
  String get tooManyRequests  => _t('Ko\'p urinish! Biroz kuting', 'Too many attempts! Please wait', 'Слишком много попыток! Подождите');
  String get userDisabled     => _t('Bu hisob bloklangan', 'This account is disabled', 'Этот аккаунт заблокирован');
  String get networkError     => _t('Internet aloqasini tekshiring', 'Check your internet connection', 'Проверьте интернет-соединение');
  String get emptyEmail       => _t('Email kiritilmagan', 'Email is required', 'Введите email');
  String get emptyPassword    => _t('Parol kiritilmagan', 'Password is required', 'Введите пароль');

  // Register screen
  String get register => _t("Ro'yhatdan o'tish", 'Register', 'Зарегистрироваться');
  String get createStudentAccount => _t('Talaba hisobi yaratish', 'Create student account', 'Создание аккаунта студента');
  String get personalInfo => _t("Shaxsiy ma'lumotlar", 'Personal info', 'Личные данные');
  String get educationInfo => _t("Ta'lim ma'lumotlari", 'Education info', 'Учебные данные');
  String get degree => _t('Daraja *', 'Degree *', 'Степень *');
  String get facultyLabel => _t('Fakultet', 'Faculty', 'Факультет');
  String get directionLabel => _t("Yo'nalish", 'Direction', 'Направление');
  String get groupHint => _t('Guruh (masalan: MTI-21)', 'Group (e.g.: MTI-21)', 'Группа (напр.: MTI-21)');
  String get passwordLabel => _t('Parol', 'Password', 'Пароль');
  String get passwordHint => _t('Parol * (kamida 6 ta belgi)', 'Password * (min 6 chars)', 'Пароль * (мин. 6 символов)');
  String get confirmPassword => _t('Parolni tasdiqlang *', 'Confirm password *', 'Подтвердите пароль *');
  String get haveAccount => _t('Hisobingiz bormi? ', 'Have an account? ', 'Есть аккаунт? ');
  String get emailPhone => _t('Telefon raqam *', 'Phone number *', 'Номер телефона *');
  String get fillAllFields => _t("Barcha majburiy maydonlarni to'ldiring", 'Fill all required fields', 'Заполните все обязательные поля');
  String get passwordMismatch => _t("Parollar mos kelmaydi", 'Passwords do not match', 'Пароли не совпадают');
  String get passwordTooShort => _t("Parol kamida 6 ta belgidan iborat bo'lishi kerak", 'Password must be at least 6 characters', 'Пароль должен содержать минимум 6 символов');

  // Admin navigation
  String get navReservations => _t('Bronlar', 'Reservations', 'Брони');

  // Dashboard
  String get librarianPanel => _t('Kutubxonachi paneli', 'Librarian panel', 'Панель библиотекаря');
  String get totalBooks => _t('Jami kitob', 'Total books', 'Всего книг');
  String get studentsLabel => _t('Talabalar', 'Students', 'Студенты');
  String overdueCount(int n) => _t('$n ta muddati o\'tgan bron', '$n overdue reservations', '$n просроченных броней');
  String returnReqCount(int n) => _t('$n ta qaytarish so\'rovi kutilmoqda', '$n return requests pending', '$n запросов на возврат');
  String get recentReservations => _t("So'nggi bronlar", 'Recent reservations', 'Последние брони');

  // Books management
  String get editBook => _t('Kitobni tahrirlash', 'Edit book', 'Редактировать книгу');
  String get addBook => _t('Kitob qo\'shish', 'Add book', 'Добавить книгу');
  String get bookTitleHint => _t('Kitob nomi *', 'Book title *', 'Название книги *');
  String get authorHint => _t('Muallif *', 'Author *', 'Автор *');
  String get descriptionHint => _t('Tavsif', 'Description', 'Описание');
  String get totalCountHint => _t('Umumiy soni', 'Total count', 'Общее количество');
  String get categoryLabel => _t('Kategoriya', 'Category', 'Категория');
  String get add => _t('Qo\'shish', 'Add', 'Добавить');
  String get deleteBookTitle => _t("Kitobni o'chirish", 'Delete book', 'Удалить книгу');
  String deleteConfirm(String title) => _t('"$title" kitobini o\'chirishni tasdiqlaysizmi?', 'Delete "$title"?', '"$title" ni o\'chirish?');
  String get cancel => _t('Bekor', 'Cancel', 'Отмена');
  String get delete => _t("O'chirish", 'Delete', 'Удалить');

  // Reservations management
  String get reservationNotFound => _t('Bron topilmadi', 'Reservation not found', 'Бронь не найдена');
  String get filterNeedsConfirm => _t('Tasdiq kerak', 'Needs confirm', 'Нужно подтвердить');
  String dueDateLabel(String date) => _t('Muddat: $date', 'Due: $date', 'Срок: $date');
  String get confirm => _t('Tasdiqlash', 'Confirm', 'Подтвердить');
  String get accept => _t('Qabul qilish', 'Accept', 'Принять');
  String get returnedAction => _t('Qaytarildi', 'Returned', 'Возвращено');

  // Announcements management
  String get addAnnouncement => _t("E'lon qo'shish", 'Add announcement', 'Добавить объявление');
  String get annTitleHint => _t('Sarlavha *', 'Title *', 'Заголовок *');
  String get annContentHint => _t('Mazmun *', 'Content *', 'Содержание *');
  String get annType => _t('Turi', 'Type', 'Тип');
  String get importantAnn => _t("Muhim e'lon", 'Important announcement', 'Важное объявление');

  // Room booking
  String get navRooms         => _t('Xona', 'Room', 'Комната');
  String get roomsTitle       => _t('Kutubxona xonalari', 'Library Rooms', 'Комнаты библиотеки');
  String get bookSeat         => _t('Joy bron qilish', 'Book a seat', 'Забронировать место');
  String get mySeatBookings   => _t('Xona bronlarim', 'My seat bookings', 'Мои брони мест');
  String get selectDate       => _t('Sanani tanlang', 'Select date', 'Выберите дату');
  String get selectStartTime  => _t('Boshlanish vaqti', 'Start time', 'Начало');
  String get selectEndTime    => _t('Tugash vaqti', 'End time', 'Конец');
  String get showAvailability => _t('Mavjudlikni ko\'rish', 'Show availability', 'Показать доступность');
  String get noRooms          => _t('Xonalar topilmadi', 'No rooms found', 'Комнаты не найдены');
  String get noSeatBookings   => _t('Xona bronlari yo\'q', 'No seat bookings', 'Нет броней мест');
  String get addRoom          => _t('Xona qo\'shish', 'Add room', 'Добавить комнату');
  String get editRoom         => _t('Xonani tahrirlash', 'Edit room', 'Редактировать комнату');
  String get roomNameHint     => _t('Xona nomi *', 'Room name *', 'Название комнаты *');
  String get capacityHint     => _t('Sig\'imlilik (o\'rin soni) *', 'Capacity (seats) *', 'Вместимость (мест) *');
  String get roomDescHint     => _t('Tavsif (ixtiyoriy)', 'Description (optional)', 'Описание (необязательно)');
  String get blockTime        => _t('Vaqtni bloklash', 'Block time slot', 'Заблокировать время');
  String get blockReasonHint  => _t('Bloklash sababi *', 'Block reason *', 'Причина блокировки *');
  String get blockedTimes     => _t('Bloklangan vaqtlar', 'Blocked times', 'Заблокированные времена');
  String get noBlocks         => _t('Bloklangan vaqt yo\'q', 'No blocked times', 'Нет заблокированных времён');
  String get roomBlocked      => _t('Bu vaqt bloklangan', 'This time is blocked', 'Это время заблокировано');
  String get bookingSuccess   => _t('Joy muvaffaqiyatli bron qilindi!', 'Seat booked successfully!', 'Место успешно забронировано!');
  String get cancelBooking    => _t('Bronni bekor qilish', 'Cancel booking', 'Отменить бронь');
  String get bookingCancelled => _t('Bron bekor qilindi', 'Booking cancelled', 'Бронь отменена');
  String get upcoming         => _t('Kelayotgan', 'Upcoming', 'Предстоящие');
  String get pastLabel        => _t('O\'tgan', 'Past', 'Прошедшие');
  String get viewRoomBookings => _t('Bronlarni ko\'rish', 'View bookings', 'Просмотреть брони');
  String get deleteRoom       => _t('Xonani o\'chirish', 'Delete room', 'Удалить комнату');
  String get workingHours     => _t('Ish vaqti', 'Working hours', 'Рабочие часы');
  String get openTime         => _t('Ochilish', 'Opens', 'Открывается');
  String get closeTime        => _t('Yopilish', 'Closes', 'Закрывается');
  String get outsideHours     => _t('Ish vaqtidan tashqari', 'Outside hours', 'Вне рабочего времени');
  String seatsAvailable(int n) => _t('$n joy bo\'sh', '$n seats free', '$n мест свободно');
  String seatsOf(int a, int t)  => _t('$a/$t joy', '$a/$t seats', '$a/$t мест');
  String get blocked          => _t('Bloklangan', 'Blocked', 'Заблокировано');
  String get selectTimeFirst  => _t('Vaqtni tanlang', 'Select time first', 'Сначала выберите время');
  String get roomBookings     => _t('Xona bronlari', 'Room bookings', 'Брони комнаты');
  String get weeklyView       => _t('Haftalik jadval', 'Weekly schedule', 'Недельное расписание');
  String get dayView          => _t('Kunlik', 'Daily', 'Дневной');
  String get thisWeek         => _t('Bu hafta', 'This week', 'Эта неделя');
  String get prevWeek         => _t('Oldingi hafta', 'Previous week', 'Предыдущая неделя');
  String get nextWeek         => _t('Keyingi hafta', 'Next week', 'Следующая неделя');
  String get noBookingsDay    => _t('Bu kunda bron yo\'q', 'No bookings this day', 'Нет броней в этот день');
  String weekBookingCount(int n) => _t('$n ta bron', '$n bookings', '$n броней');
  String get selectDayToBook  => _t('Kun tanlang va bron qiling', 'Select a day to book', 'Выберите день для бронирования');

  // Reviews & Questions
  String get reviews        => _t('Sharhlar', 'Reviews', 'Отзывы');
  String get questions      => _t('Savollar', 'Questions', 'Вопросы');
  String get ratingLabel    => _t('Reyting', 'Rating', 'Рейтинг');
  String get writeReview    => _t('Sharh yozing', 'Write a review', 'Написать отзыв');
  String get submitReview   => _t('Sharh yuborish', 'Submit review', 'Отправить отзыв');
  String get askQuestion    => _t('Savol bering', 'Ask a question', 'Задать вопрос');
  String get submitQuestion => _t('Savol yuborish', 'Submit question', 'Отправить вопрос');
  String get writeAnswer    => _t('Javob yozing', 'Write an answer', 'Написать ответ');
  String get submitAnswer   => _t('Javob yuborish', 'Submit answer', 'Отправить ответ');
  String get noReviews      => _t("Hali sharh yo'q", 'No reviews yet', 'Отзывов пока нет');
  String get noQuestions    => _t("Hali savol yo'q", 'No questions yet', 'Вопросов пока нет');
  String get alreadyReviewed => _t('Siz allaqachon sharh qoldirdingiz', 'You already reviewed this book', 'Вы уже оставили отзыв');
  String get reviewEligible  => _t("Kitobni qaytargandan keyin sharh qoldirishingiz mumkin", 'You can review after returning the book', 'Вы можете оставить отзыв после возврата книги');
  String get answeredBy     => _t('Javob berdi', 'Answered by', 'Ответил(а)');
  String get unanswered     => _t('Javobsiz', 'Unanswered', 'Без ответа');
  String get bookInfo       => _t('Kitob', 'Book', 'Книга');
  String get yourComment    => _t('Izohingiz (ixtiyoriy)...', 'Your comment (optional)...', 'Ваш комментарий (необязательно)...');
  String get yourQuestion   => _t('Savolingizni yozing...', 'Write your question...', 'Напишите ваш вопрос...');
  String get yourAnswer     => _t('Javobingizni yozing...', 'Write your answer...', 'Напишите ваш ответ...');
  String reviewCount(int n) => _t('$n ta sharh', '$n reviews', '$n отзывов');
  String get notifications   => _t('Bildirishnomalar', 'Notifications', 'Уведомления');
  String get noNotifications => _t('Bildirishnomalar yo\'q', 'No notifications', 'Нет уведомлений');
  String viewsCount(int n) => _t('$n marta ko\'rilgan', '$n views', '$n просмотров');
  String get borrowedBy => _t('Kim olgan', 'Borrowed by', 'Взял(а)');
  String get studentDetails => _t('Talaba ma\'lumotlari', 'Student details', 'Данные студента');

  // Room schedule
  String get roomSchedule     => _t('Xona jadvali', 'Room schedule', 'Расписание комнаты');
  String get scheduleBtn      => _t('Jadval', 'Schedule', 'Расписание');
  String get today            => _t('Bugun', 'Today', 'Сегодня');
  String get tomorrow         => _t('Ertaga', 'Tomorrow', 'Завтра');
  String get yourBookingLabel => _t('Sizning broningiz', 'Your booking', 'Ваша бронь');
  String get seatsUnit        => _t('o\'rin', 'seats', 'мест');
  String get bookingsCount    => _t('ta bron', 'bookings', 'броней');

  // Announcement image
  String get annImageHint => _t('Rasm URL (ixtiyoriy)', 'Image URL (optional)', 'URL изображения (необязательно)');

  // Full day block
  String get fullDayBlock    => _t('Butun kunni yopish', 'Block full day', 'Заблокировать весь день');
  String get fullDayLabel    => _t('Butun kun', 'Full day', 'Весь день');
  String get holidayReason   => _t('Dam olish / Bayram kuni', 'Holiday / Day off', 'Выходной / Праздник');
  String get dayHasBlocks    => _t('Bu kunda ba\'zi vaqtlar yopiq', 'Some times blocked this day', 'В этот день некоторое время закрыто');
  String get bookFromSlot    => _t('Bron qilish', 'Book this slot', 'Забронировать');

  // Fixed time slots
  String get selectDuration  => _t('Davomiylik tanlang', 'Select duration', 'Выберите длительность');
  String get selectSlot      => _t('Vaqt tanlang', 'Select time', 'Выберите время');
  String hour(int n)         => _t('${n} soat', '${n} hour${n > 1 ? "s" : ""}', '${n} ч.');
  String get slotAuto        => _t('Vaqt avtomatik hisoblanadi', 'Time auto-calculated', 'Время подсчитывается');

  // Booking actions
  String get confirmArrival  => _t('Dars tasdiqlash', 'Confirm arrival', 'Подтвердить прибытие');
  String get leavingEarly    => _t('Ketdim', 'I\'m leaving', 'Ухожу');
  String get bookingConfirmed => _t('Kelishingiz tasdiqlandi!', 'Arrival confirmed!', 'Прибытие подтверждено!');
  String get leftEarly       => _t('Joy bo\'shatildi', 'Seat freed', 'Место освобождено');
  String get cancelTooLate   => _t('Boshlanishga 30 daqiqa qoldi, bekor bo\'lmaydi', 'Less than 30 min to start', 'Менее 30 мин до начала');
  String minutesLeft(int n)  => _t('$n daqiqa qoldi', '$n min left', '$n мин. осталось');
  String get confirmWindow   => _t('Tasdiqlash oynasi ochiq', 'Confirm window open', 'Окно подтверждения открыто');
  String get viewDetails     => _t('Batafsil', 'Details', 'Подробнее');
  String get noShowWarning   => _t('Kelmasangiz, cheklov qo\'yiladi!', 'No-show penalty applies!', 'Штраф за неявку!');

  // Status labels
  String get statusConfirmed => _t('Tasdiqlangan', 'Confirmed', 'Подтверждено');
  String get statusLeft      => _t('Erta chiqqan', 'Left early', 'Ушёл раньше');
  String get statusNoShow    => _t('Kelmagan', 'No-show', 'Не явился');

  String _t(String uz, String en, String ru) {
    if (lang == 'ru') return ru;
    if (lang == 'en') return en;
    return uz;
  }
}