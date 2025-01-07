module Account::EntriesHelper
  def permitted_entryable_partial_path(entry, relative_partial_path)
    "account/entries/entryables/#{permitted_entryable_key(entry)}/#{relative_partial_path}"
  end

  def transfer_entries(entries)
    transfers = entries.select { |e| e.transfer_id.present? }
    transfers.map(&:transfer).uniq
  end

  def entries_by_date(entries, selectable: true, totals: false)
    entries.reverse_chronological.group_by(&:date).map do |date, grouped_entries|
      content = capture do
        yield grouped_entries
      end

      next if content.blank?

      render partial: "account/entries/entry_group", locals: { date:, entries: grouped_entries, content:, selectable:, totals: }
    end.compact.join.html_safe
  end

  def entry_name_detailed(entry)
    [
      entry.date,
      format_money(entry.amount_money),
      entry.account.name,
      entry.display_name
    ].join(" • ")
  end

  private

    def permitted_entryable_key(entry)
      permitted_entryable_paths = %w[transaction valuation trade]
      entry.entryable_name_short.presence_in(permitted_entryable_paths)
    end
end
