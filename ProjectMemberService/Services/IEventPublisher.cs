using System.Threading.Tasks;

namespace ProjectMemberService.Services
{
    public interface IEventPublisher
    {
        Task PublishAsync<T>(string eventName, T eventData);
    }
}
