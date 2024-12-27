# Loftwah's SitrepSender

Welcome to **Loftwah's SitrepSender**! This is your one-stop solution for generating and sending beautifully styled email reports. Whether it’s a **Daily Summary**, **Weekly Sitrep**, **Fortnightly Update**, or a **Monthly Round-Up**, SitrepSender has got you covered.

---

## Features

- **Dynamic Personalisation**: Automatically creates reports with customised titles like _Loftwah's Weekly Sitrep_, _Loftwah's Fortnightly Update_, or _Loftwah's Monthly Sitrep_.
- **Markdown to Magic**: Transforms Markdown into sleek HTML emails with inline styles.
- **Image Attachments**: Handles local images by attaching them to emails and replacing inline images with descriptive notes.
- **Environment Configuration**: Seamlessly integrates with `.env` for secure handling of API keys and email credentials.
- **Workflow Ready**: Perfectly tailored for **GitHub Actions**, automating your reporting process like a true pro.

---

## Prerequisites

- **Ruby 3.3+**: To run the script.
- **Bundler**: For managing dependencies.
- **Resend Account**: To send emails via their API.
- **GitHub Actions**: For automation (optional).

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/loftwah/SitrepSender.git
cd SitrepSender
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Set Up Environment Variables

Create a `.env` file in the root directory with the following:

```env
RESEND_API_KEY=<your_resend_api_key>
SENDER_EMAIL=<your_sender_email>
RECIPIENT_EMAIL=<recipient_email>
REPORT_PERIOD=Weekly
```

---

## Usage

### 1. Prepare Your Content

- Place Markdown or HTML files in the `./reports` directory. These files should contain the specific information you want included in your report. For example:
  - **Daily**: Key metrics, logs, or events from the last 24 hours.
  - **Weekly**: Summaries, highlights, or performance trends for the week.
  - **Fortnightly**: Mid-month updates or milestones.
  - **Monthly**: Comprehensive overviews, project progress, or financial summaries.

**Important**: The script doesn’t validate or modify the content; it simply generates and sends whatever is in the `reports/` directory. Ensure you’ve placed the correct files for the desired period.

### 2. Run the Script

```bash
ruby email_report.rb
```

### 3. Dynamic Subject Line

- The email subject dynamically changes based on the `REPORT_PERIOD`, for example:
  ```
  Loftwah's Daily Sitrep
  Loftwah's Weekly Sitrep
  Loftwah's Fortnightly Update
  Loftwah's Monthly Sitrep
  ```

---

## GitHub Actions Integration

Want to automate this like a boss? Here’s how you can set up GitHub Actions to send reports daily, weekly, fortnightly, or monthly.

### `.github/workflows/sitrep_sender.yml`

```yaml
name: Send Loftwah's Sitrep

on:
  schedule:
    - cron: "0 8 * * *" # Daily at 8:00 AM UTC
    - cron: "0 8 * * 1" # Weekly on Monday at 8:00 AM UTC
    - cron: "0 8 1,15 * *" # Fortnightly on the 1st and 15th of each month
    - cron: "0 8 1 * *" # Monthly on the 1st at 8:00 AM UTC

jobs:
  send-sitrep:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Install Ruby 3.3
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
          bundler-cache: true

      - name: Install Dependencies
        run: bundle install

      - name: Send Sitrep
        env:
          RESEND_API_KEY: ${{ secrets.RESEND_API_KEY }}
          SENDER_EMAIL: ${{ secrets.SENDER_EMAIL }}
          RECIPIENT_EMAIL: ${{ secrets.RECIPIENT_EMAIL }}
        run: |
          case $(date +"%d") in
            01) REPORT_PERIOD=Monthly ruby email_report.rb ;;
            15) REPORT_PERIOD=Fortnightly ruby email_report.rb ;;
            *) REPORT_PERIOD=Daily ruby email_report.rb ;;
          esac
```

### Explanation

#### **Report Periods**

- **Daily Reports**: Sent every day at 8:00 AM UTC (cron: `0 8 * * *`).
- **Weekly Reports**: Sent every Monday at 8:00 AM UTC (cron: `0 8 * * 1`).
- **Fortnightly Reports**: Sent on the 1st and 15th of each month (cron: `0 8 1,15 * *`).
- **Monthly Reports**: Sent on the 1st of each month (cron: `0 8 1 * *`).

#### **What Is UTC?**

UTC (Coordinated Universal Time) is the global standard for timekeeping, unaffected by time zones or daylight saving. To calculate your local time:

- Use online tools like [Time Zone Converter](https://www.timeanddate.com/worldclock/converter.html).
- Example: 8:00 AM UTC is:
  - 7:00 PM AEDT (Sydney)
  - 12:00 AM PST (Los Angeles)

---

## Project Structure

```plaintext
.
├── email_report.rb        # The brains of the operation
├── reports/               # Markdown/HTML files for your content
├── Gemfile                # Gem dependencies
├── Gemfile.lock           # Locked gem versions
├── .env                   # Environment variables (ignored in Git)
├── .github/workflows/     # GitHub Actions workflows
└── README.md              # This epic guide
```

---

## Customisation

### Dynamic Report Periods

The `REPORT_PERIOD` environment variable controls the report type. Defaults to `Weekly`, but you can set it to `Daily`, `Fortnightly`, `Monthly`, or any custom value. This also updates the email subject and header.

### Style Tweaks

The email design is controlled by inline CSS in the `generate_report` method. Update it to match your style.

---

## Troubleshooting

### Common Issues

#### 1. **Environment Variables Not Loaded**

- Ensure the `.env` file exists and contains valid values.

#### 2. **Resend API Errors**

- Double-check your `RESEND_API_KEY`.
- Ensure sender and recipient emails are valid.

#### 3. **Missing Content**

- Make sure you’ve added Markdown or HTML files to the `./reports` directory.

### Debugging

Run the script with detailed logs:

```bash
DEBUG=true ruby email_report.rb
```

---

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request with detailed explanations of changes.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Acknowledgements

Shoutout to:

- [Redcarpet](https://github.com/vmg/redcarpet)
- [dotenv](https://github.com/bkeepers/dotenv)
- [Resend API](https://resend.com)

Loftwah out! 🚀
