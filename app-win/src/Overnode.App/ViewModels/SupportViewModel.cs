using System;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class SupportViewModel : ObservableObject
{
    private readonly SupportService _service = SupportService.Instance;

    [ObservableProperty]
    private ObservableCollection<SupportTicket> _tickets = new();

    [ObservableProperty]
    private SupportTicket? _selectedTicket;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isCreatingTicket;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private string _newTicketSubject = string.Empty;

    [ObservableProperty]
    private string _newTicketCategory = "Serveurs";

    [ObservableProperty]
    private string _newTicketPriority = "normal";

    [ObservableProperty]
    private string _newTicketDescription = string.Empty;

    [ObservableProperty]
    private string _replyMessage = string.Empty;

    public SupportViewModel() { }

    public async Task LoadTicketsAsync()
    {
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var res = await _service.FetchTicketsAsync();
            Tickets.Clear();
            foreach (var t in res.Data)
            {
                Tickets.Add(t);
            }
            if (SelectedTicket == null && Tickets.Count > 0)
            {
                SelectedTicket = Tickets[0];
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task<bool> CreateTicketAsync()
    {
        if (string.IsNullOrWhiteSpace(NewTicketSubject) || string.IsNullOrWhiteSpace(NewTicketDescription))
            return false;

        IsCreatingTicket = true;
        ErrorMessage = null;

        try
        {
            var payload = new CreateTicketPayload
            {
                Subject = NewTicketSubject.Trim(),
                Category = NewTicketCategory,
                Priority = NewTicketPriority,
                Description = NewTicketDescription.Trim()
            };

            var ticket = await _service.CreateTicketAsync(payload);
            Tickets.Insert(0, ticket);
            SelectedTicket = ticket;

            NewTicketSubject = string.Empty;
            NewTicketDescription = string.Empty;
            return true;
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            return false;
        }
        finally
        {
            IsCreatingTicket = false;
        }
    }

    public async Task<bool> SendReplyAsync()
    {
        if (SelectedTicket == null || string.IsNullOrWhiteSpace(ReplyMessage))
            return false;

        try
        {
            var msg = await _service.SendMessageAsync(SelectedTicket.Id, ReplyMessage.Trim());
            SelectedTicket.Messages.Add(msg);
            ReplyMessage = string.Empty;
            OnPropertyChanged(nameof(SelectedTicket));
            return true;
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            return false;
        }
    }
}
