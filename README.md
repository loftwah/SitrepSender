# Loftwah's SitrepSender

Welcome to **Loftwah's SitrepSender**! This is your one-stop solution for generating and sending beautifully styled email reports. Whether it’s a **Daily Summary**, **Weekly Sitrep**, **Fortnightly Update**, or a **Monthly Round-Up**, SitrepSender has got you covered.

---

## Features

- **Dynamic Personalisation**: Automatically creates reports with customised titles like _Loftwah's Weekly Sitrep_, _Loftwah's Fortnightly Update_, or _Loftwah's Monthly Sitrep_.
- **Markdown and HTML Handling**: Transforms Markdown and HTML content into sleek emails with inline styles.
- **Image Attachments**: Handles local images by attaching them to emails and replacing inline references with descriptive notes.
- **Directory Organisation**: Separate directories for daily, weekly, fortnightly, and monthly reports to avoid conflicts.
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
RECIPIENT_EMAIL=<recipient_email_or_array>
REPORT_PERIOD=Weekly
```

#### **RECIPIENT_EMAIL Format**

- For a **single recipient**, use a plain string:
  ```env
  RECIPIENT_EMAIL=dean@deanlofts.xyz
  ```
- For **multiple recipients**, use a JSON array:
  ```env
  RECIPIENT_EMAIL=["dean@deanlofts.xyz", "other@domain.com"]
  ```

The script will handle both formats seamlessly.

#### **REPORT_PERIOD Default**

- Defaults to `Weekly` if not specified.
- Options: `Daily`, `Weekly`, `Fortnightly`, `Monthly`, or custom values. This also determines the corresponding directory (`reports/<period>/`).

---

## Usage

### 1. Directory Structure

To avoid conflicts and organise content by report type, use the following directory structure:

```plaintext
reports/
├── daily/
├── weekly/
├── fortnightly/
└── monthly/
```

Each directory should contain the Markdown or HTML files for the respective report period. For example:

- **Daily Reports**: Place daily logs, key metrics, or summaries in `reports/daily/`.
- **Weekly Reports**: Add weekly summaries, highlights, or trends to `reports/weekly/`.
- **Fortnightly Reports**: Include mid-month updates or milestones in `reports/fortnightly/`.
- **Monthly Reports**: Add comprehensive overviews, project progress, or financial summaries to `reports/monthly/`.

**Important**: If a directory is empty, the script will skip generating and sending a report for that period.

### 2. Run the Script

```bash
ruby email_report.rb
```

### 3. Dynamic Subject Line

The email subject dynamically changes based on the `REPORT_PERIOD`, for example:

```plaintext
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
          REPORT_DIR="reports/${{ env.REPORT_PERIOD }}"
          if [ -d "$REPORT_DIR" ] && [ "$(ls -A $REPORT_DIR)" ]; then
            ruby email_report.rb
          else
            echo "No content found in $REPORT_DIR, skipping report."
          fi
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
│   ├── daily/
│   ├── weekly/
│   ├── fortnightly/
│   └── monthly/
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

- Make sure you’ve added Markdown or HTML files to the appropriate `reports/` subdirectory.

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
