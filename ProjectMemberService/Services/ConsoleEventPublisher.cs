using System.Text.Json;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace ProjectMemberService.Services
{
    public class ConsoleEventPublisher : IEventPublisher
    {
        private readonly ILogger<ConsoleEventPublisher> _logger;

        public ConsoleEventPublisher(ILogger<ConsoleEventPublisher> logger)
        {
            _logger = logger;
        }

        public Task PublishAsync<T>(string eventName, T eventData)
        {
            var payload = JsonSerializer.Serialize(eventData, new JsonSerializerOptions 
            { 
                WriteIndented = true 
            });
            _logger.LogInformation("\n[EVENT PUBLISHED] Event: {EventName}\nPayload:\n{Payload}\n", eventName, payload);
            return Task.CompletedTask;
        }
    }
}
