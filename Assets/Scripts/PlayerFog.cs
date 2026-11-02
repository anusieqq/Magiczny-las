
using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class FogPlayerExclusion : MonoBehaviour
{
    [Header("Player")]
    [SerializeField] private Transform player;

    private Renderer fogRenderer;
    private MaterialPropertyBlock properties;

    private static readonly int PlayerPositionID =
        Shader.PropertyToID("_PlayerPosition");

    private void Awake()
    {
        fogRenderer = GetComponent<Renderer>();
        properties = new MaterialPropertyBlock();
    }

    private void LateUpdate()
    {
        if (player == null || fogRenderer == null)
            return;

        Vector3 playerPosition = player.position;

        fogRenderer.GetPropertyBlock(properties);

        properties.SetVector(
            PlayerPositionID,
            new Vector4(
                playerPosition.x,
                playerPosition.y,
                playerPosition.z,
                1f
            )
        );

        fogRenderer.SetPropertyBlock(properties);
    }
}
