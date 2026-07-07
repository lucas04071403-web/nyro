# Nyro

Nyro یک کلاینت چندسکویی پروکسی/VPN برای Android، Windows، macOS و Linux است.

Nyro بر پایه Hiddify App توسعه ثانویه داده شده است. این پروژه از Hiddify Core و Sing-box برای قابلیت های اصلی پروکسی استفاده می کند، مجوز و انتساب پروژه بالادستی را حفظ می کند و در عین حال برند، شناسه بسته، لینک دانلود و کانال انتشار مستقل Nyro را ارائه می دهد.

## دانلود

https://github.com/lucas04071403-web/nyro/releases/latest

نسخه فعلی:

https://github.com/lucas04071403-web/nyro/releases/tag/v1.0.1

## قابلیت های فعلی

- پشتیبانی از Android، Windows، macOS و Linux.
- پشتیبانی از پروفایل ها و لینک های اشتراک سازگار با Sing-box، V2Ray، Clash و Clash Meta.
- مرکز کاربری متصل به حساب های Xboard.
- ثبت نام با کد تایید ایمیل، ورود و همگام سازی حساب.
- نمایش پلن های Xboard، مشخص کردن پلن فعلی و همگام سازی اشتراک.
- خرید پلن با انتخاب دوره، انتخاب روش پرداخت، پرداخت Epay یا QR، بررسی وضعیت سفارش و تازه سازی خودکار بعد از پرداخت موفق.
- سازگاری بهتر اشتراک های Xboard با Nyro، شامل حذف نودهای اطلاعاتی، خواندن header مربوط به `subscription-userinfo` و تنظیمات پروفایل پایدارتر برای Sing-box.

## به روزرسانی های اخیر

- ثبت نام Xboard با تایید ایمیل اضافه شد.
- جریان خرید اشتراک Xboard و پرداخت اضافه شد.
- نمایش پلن فعلی در فهرست اشتراک ها اضافه شد.
- parser اشتراک Xboard بهبود یافت تا پیام های ترافیک، زمان ریست و تاریخ انقضا وارد فهرست پروکسی ها نشوند.
- نمایش ترافیک و تاریخ انقضا با استفاده از header مربوط به `subscription-userinfo` بهبود یافت.
- تنظیمات پیش فرض مناسب تر برای اشتراک های Xboard اعمال شد، از جمله تست سریع تر URL، DNS با اولویت IPv4 و فاصله کوتاه تر برای به روزرسانی خودکار.

## مجوز و انتساب

Nyro بر پایه Hiddify App توسعه داده شده است:

https://github.com/hiddify/hiddify-app

همچنین از Hiddify Core و Sing-box استفاده می کند:

https://github.com/hiddify/hiddify-core

https://github.com/SagerNet/sing-box

برای جزئیات مجوز و انتساب، `LICENSE.md`، `NOTICE.md` و `ACKNOWLEDGEMENTS.md` را ببینید.
